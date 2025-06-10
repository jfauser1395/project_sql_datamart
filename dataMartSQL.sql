-- This SQL script creates a database schema for an AirBnB-like application.
-- All primary keys are typed CHAR(36) for UUIDs these are generated with UUID() function.


-- Create a new database named AirBnB_like_Db
CREATE DATABASE IF NOT EXISTS AirBnB_like_Db;

-- Use the newly created database
USE AirBnB_like_Db;


-- Superclass Table: User
-- This table stores all common attributes for every user
-- The user_type column acts as a discriminator to identify
-- which subclass table holds additional specific information
CREATE TABLE User (
  user_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  user_type ENUM('host', 'guest', 'admin') NOT NULL, -- Discriminator column
  first_name VARCHAR(25) NOT NULL, -- First name of the user
  last_name VARCHAR(25) NOT NULL, -- Last name of the user
  email VARCHAR(50) NOT NULL UNIQUE, -- Email should be unique
  phone_number VARCHAR(50) NULL, -- Phone number can be optional
  password_hash VARCHAR(255) NOT NULL, -- Stores the hashed password
  profile_picture VARCHAR(255) NULL, -- URL or path to profile picture, optional
  creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Automatically set on creation
  last_login TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, -- Updates when the record is modified, can be used to track last login
  CONSTRAINT pk_user_id PRIMARY KEY (user_id) -- Primary Key constraint
);

-- Subclass Table: Admin
-- Stores attributes specific to Admin users.
-- user_id is both the Primary Key and a Foreign Key referencing User.user_id
CREATE TABLE Admin (
  admin_id CHAR(36) NOT NULL, -- References User.user_id
  role ENUM('reader', 'writer') NOT NULL DEFAULT 'reader', -- Admin-specific role
  CONSTRAINT pk_admin_user PRIMARY KEY (admin_id), -- Primary Key constraint
  CONSTRAINT fk_admin_user -- Foreign Key constraint to ensure admin_id references user_id in User table
    FOREIGN KEY (admin_id) 
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If a User is deleted, the corresponding Admin record is also deleted.
    ON UPDATE CASCADE -- If a User.user_id is updated, the corresponding Admin.user_id is updated
);

-- Subclass Table: Guest
-- Stores attributes specific to Guest users.
-- user_id is both the Primary Key and a Foreign Key referencing User.user_id
CREATE TABLE Guest (
  guest_id CHAR(36) NOT NULL, -- References User.user_id
  membership_tier ENUM('free', 'premium') NOT NULL DEFAULT 'free', -- Guest-specific membership tier
  CONSTRAINT pk_guest_user PRIMARY KEY (guest_id), -- Primary Key constraint
  CONSTRAINT fk_guest_user -- Foreign Key constraint to ensure guest_id references user_id in User table
    FOREIGN KEY (guest_id) 
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If a User is deleted, the corresponding Guest record is also deleted
    ON UPDATE CASCADE -- If a User.user_id is updated, the corresponding Guest.user_id is updated
);

-- Subclass Table: Host
-- Stores attributes specific to Host users.
-- user_id is both the Primary Key and a Foreign Key referencing User.user_id
CREATE TABLE Host (
  host_id CHAR(36) NOT NULL, -- References User.user_id
  host_tier ENUM('regular', 'prime') NOT NULL DEFAULT 'regular', -- Host-specific tier
  CONSTRAINT pk_host_user PRIMARY KEY (host_id), -- Primary Key constraint
  CONSTRAINT fk_host_user -- Foreign Key constraint to ensure host_id references user_id in User table
    FOREIGN KEY (host_id) 
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If a User is deleted, the corresponding Host record is also deleted.
    ON UPDATE CASCADE -- If a User.user_id is updated, the corresponding Host.user_id is updated
);

-- Property Table
-- Stores general details about a physical property
CREATE TABLE Property (
  property_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  title VARCHAR(100) NOT NULL, -- Title of the property
  country VARCHAR(100) NOT NULL, -- Country where the property is located
  state VARCHAR(100) NOT NULL, -- State/Region where the property is located
  zip_code VARCHAR(50) NOT NULL, -- Zip/Postal code
  address VARCHAR(255) NOT NULL, -- Full address of the property
  square_feet INT NULL, -- Optional field
  property_type ENUM(
   'Apartment', 'House', 'Penthouse', 'Commercial', 'Cottage',
    'Studio', 'Industrial', 'Villa', 'Flat', 'Loft',
    'Townhouse', 'Retail', 'Barn', 'Cabin', 'Mansion', 'Chalet', 'Bungalow', 'Others'
  ) NOT NULL, -- PropertyType
  CONSTRAINT pk_property PRIMARY KEY (property_id) -- Primary Key constraint
);

-- PropertyAccess Table (Junction Table)
-- Links Hosts to the Properties they have access to manage
CREATE TABLE PropertyAccess (
  host_id CHAR(36) NOT NULL, -- Foreign Key referencing Host
  property_id CHAR(36) NOT NULL, -- Foreign Key referencing Property
  CONSTRAINT pk_propertyAccess PRIMARY KEY (host_id, property_id), -- Composite Primary Key
  CONSTRAINT fk_propertyAccess_host -- Foreign Key constraint to ensure host_id references Host.host_id
    FOREIGN KEY (host_id)
    REFERENCES Host (host_id)
    ON DELETE CASCADE -- If host is deleted, remove their access
    ON UPDATE CASCADE, -- If host_id is updated, update all links
  CONSTRAINT fk_propertyAccess_property -- Foreign Key constraint to ensure property_id references Property.property_id
    FOREIGN KEY (property_id) 
    REFERENCES Property (property_id)
    ON DELETE CASCADE -- If property is deleted, remove all access links
    ON UPDATE CASCADE -- If property_id is updated, update all links
);

-- CancellationPolicy Table
-- Stores different types of cancellation policies
CREATE TABLE CancellationPolicy (
  policy_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  name VARCHAR(100) NOT NULL UNIQUE, -- Name of the policy (Unique name)
  description TEXT NOT NULL, -- Description of the policy
  CONSTRAINT pk_cancellationPolicy PRIMARY KEY (policy_id) -- Primary Key constraint
);

-- Accommodation Table
-- Represents a bookable unit within a property (e.g., a specific room, apartment)
CREATE TABLE Accommodation (
  accommodation_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  property_id CHAR(36) NOT NULL, -- Foreign Key referencing Property (Accommodation belongs to a property)
  cancellation_policy_id CHAR(36) NOT NULL, -- Foreign Key referencing CancellationPolicy (Accommodation has a policy)
  accommodation_tier ENUM('regular', 'prime') NOT NULL DEFAULT 'regular', -- Tier of the accommodation
  max_guest_count INT NOT NULL, -- Maximum number of guests allowed
  description TEXT NULL, -- Optional description of the accommodation
  price_per_night DECIMAL(15,2) NOT NULL, -- Price per night (Increased precision)
  CONSTRAINT pk_accommodation PRIMARY KEY (accommodation_id), -- Primary Key constraint
  CONSTRAINT fk_accommodation_property -- Foreign Key constraint to ensure property_id references Property.property_id
    FOREIGN KEY (property_id)
    REFERENCES Property (property_id)
    ON DELETE CASCADE -- If property deleted, its accommodations are deleted
    ON UPDATE CASCADE, -- Update property_id in Accommodation if it changes in Property
  CONSTRAINT fk_accommodation_cancellation_policy -- Foreign Key constraint to ensure cancellation_policy_id references CancellationPolicy.policy_id
    FOREIGN KEY (cancellation_policy_id)
    REFERENCES CancellationPolicy (policy_id)
    ON DELETE RESTRICT -- Prevent deleting a policy if accommodations use it
    ON UPDATE CASCADE, -- Update cancellation_policy_id in Accommodation if it changes in CancellationPolicy
  CONSTRAINT chk_accommodation_max_guests CHECK (max_guest_count > 0), -- Max guests must be positive
  CONSTRAINT chk_accommodation_price CHECK (price_per_night >= 0) -- Price must be non-negative
);

-- Booking Table
-- Stores details about property bookings
CREATE TABLE Booking (
  booking_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  guest_id CHAR(36) NOT NULL, -- Foreign Key referencing Guest.guest_id
  accommodation_id CHAR(36) NOT NULL, -- Foreign Key referencing Accommodation.accommodation_id
  start_date DATETIME NOT NULL, -- Start date of the booking
  end_date DATETIME NOT NULL, -- End date of the booking
  creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Creation date of the booking
  booking_status ENUM('pending', 'confirmed', 'cancelled', 'expired', 'checked_in', 'no_show', 'checked_out') NOT NULL DEFAULT 'pending', -- Status of the booking
  CONSTRAINT pk_booking PRIMARY KEY (booking_id), -- Primary Key constraint
  CONSTRAINT fk_booking_guest -- Foreign Key constraint to ensure guest_id references Guest.guest_id
    FOREIGN KEY (guest_id) 
    REFERENCES Guest (guest_id)
    ON DELETE RESTRICT -- Prevent deleting a guest if they have active bookings
    ON UPDATE CASCADE, -- Update guest_id in Booking if it changes in Guest
  CONSTRAINT fk_booking_accommodation -- Foreign Key constraint to ensure accommodation_id references Accommodation.accommodation_id
    FOREIGN KEY (accommodation_id) 
    REFERENCES Accommodation (accommodation_id)
    ON DELETE RESTRICT -- Prevent deleting an accommodation that has been booked
    ON UPDATE CASCADE, -- Update accommodation_id in Booking if it changes in Accommodation
  CONSTRAINT chk_booking_dates CHECK (start_date < end_date) -- Ensure end date is after start date
);

-- Review Table
-- Stores reviews left by users about other users or properties/accommodations
CREATE TABLE Review (
  review_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  reviewer_id CHAR(36) NOT NULL, -- Foreign Key referencing User (the user writing the review)
  reviewee_id CHAR(36) NOT NULL, -- Foreign Key referencing User (the user being reviewed - e.g., host)
  booking_id CHAR(36) NULL, -- Foreign Key referencing Booking (review might be tied to a booking, but maybe not required for all review types)
  rating INT NOT NULL, -- Rating given in the review (e.g., 1-5)
  comment TEXT NULL, -- Optional comment
  review_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the review was created
  CONSTRAINT pk_review PRIMARY KEY (review_id), -- Primary Key constraint
  CONSTRAINT fk_review_reviewer -- Foreign Key constraint to ensure reviewer_id references User.user_id
    FOREIGN KEY (reviewer_id)
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If user deleted, their reviews are deleted
    ON UPDATE CASCADE, -- Update reviewer_id in Review if it changes in User
  CONSTRAINT fk_review_reviewee -- Foreign Key constraint to ensure reviewee_id references User.user_id
    FOREIGN KEY (reviewee_id)
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If user deleted, reviews about them are deleted (Alternative: SET NULL if reviews about deleted users should persist)
    ON UPDATE CASCADE, -- Update reviewee_id in Review if it changes in User
  CONSTRAINT fk_review_booking -- Foreign Key constraint to ensure booking_id references Booking.booking_id
    FOREIGN KEY (booking_id) 
    REFERENCES Booking (booking_id)
    ON DELETE SET NULL -- If a booking is deleted, reviews linked to it are unlinked
    ON UPDATE CASCADE, -- Update booking_id in Review if it changes in Booking
  CONSTRAINT chk_review_rating CHECK (rating >= 1 AND rating <= 5) -- Ensure rating is within a valid range
);

-- Wishlist Table
-- Stores wishlists created by guests
CREATE TABLE Wishlist (
  wishlist_id CHAR(36) NOT NULL, -- Primary Key
  guest_id CHAR(36) NOT NULL, -- Foreign Key referencing Guest (A wishlist belongs to a guest)
  title VARCHAR(100) NOT NULL, -- Title of the wishlist
  creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the wishlist was created
  CONSTRAINT pk_wishlist PRIMARY KEY (wishlist_id), -- Primary Key constraint
  CONSTRAINT fk_wishlist_guest -- Foreign Key constraint to ensure guest_id references Guest.guest_id
    FOREIGN KEY (guest_id) 
    REFERENCES Guest (guest_id)
    ON DELETE CASCADE -- If a guest is deleted, their wishlists are deleted
    ON UPDATE CASCADE -- Update guest_id in Wishlist if it changes in Guest
);

-- WishlistItem Table (Junction Table)
-- Links Accommodations to Wishlists they are included in
CREATE TABLE WishlistItem (
  wishlist_id CHAR(36) NOT NULL, -- Foreign Key referencing Wishlist
  accommodation_id CHAR(36) NOT NULL, -- Foreign Key referencing Accommodation
  CONSTRAINT pk_wishlistitem PRIMARY KEY (wishlist_id, accommodation_id), -- Composite Primary Key
  CONSTRAINT fk_wishlistitem_wishlist -- Foreign Key constraint to ensure wishlist_id references Wishlist.wishlist_id
    FOREIGN KEY (wishlist_id)
    REFERENCES Wishlist (wishlist_id)
    ON DELETE CASCADE -- If wishlist deleted, its items are deleted
    ON UPDATE CASCADE, -- Update wishlist_id in WishlistItem if it changes in Wishlist
  CONSTRAINT fk_wishlistitem_accommodation -- Foreign Key constraint to ensure accommodation_id references Accommodation.accommodation_id
    FOREIGN KEY (accommodation_id)
    REFERENCES Accommodation (accommodation_id)
    ON DELETE CASCADE -- If accommodation deleted, remove from wishlists
    ON UPDATE CASCADE -- Update accommodation_id in WishlistItem if it changes in Accommodation
);

-- Payout Table
-- Stores records of payouts made to hosts
CREATE TABLE Payout (
  payout_id CHAR(36) NOT NULL, -- Primary Key
  host_id CHAR(36) NOT NULL, -- Foreign Key referencing Host (Payout is made to a host)
  amount DECIMAL(10,2) NOT NULL, -- Payout amount (Increased precision)
  status ENUM('pending', 'completed', 'failed') NOT NULL DEFAULT 'pending', -- Payout status
  payout_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the payout was initiated/processed
  CONSTRAINT pk_payout PRIMARY KEY (payout_id), -- Primary Key constraint
  CONSTRAINT fk_payout_host -- Foreign Key constraint to ensure host_id references Host.host_id
    FOREIGN KEY (host_id)
    REFERENCES Host (host_id)
    ON DELETE RESTRICT -- Prevent deleting a host if they have payout records
    ON UPDATE CASCADE, -- Update host_id in Payout if it changes in Host
  CONSTRAINT chk_payout_amount CHECK (amount >= 0) -- Ensure amount is not negative
);

-- AccommodationImage Table
-- Stores images associated with an Accommodation
CREATE TABLE AccommodationImage (
  image_id CHAR(36) NOT NULL, -- Primary Key
  accommodation_id CHAR(36) NOT NULL, -- Foreign Key referencing Accommodation
  url VARCHAR(255) NOT NULL UNIQUE, -- URL of the image (Should be unique)
  caption VARCHAR(255) NULL, -- Optional caption for the image
  display_order INT NOT NULL DEFAULT 0, -- Order to display the image
  upload_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the image was uploaded
  CONSTRAINT pk_accommodationimage PRIMARY KEY (image_id),
  CONSTRAINT fk_accommodationimage_accommodation -- Foreign Key constraint to ensure accommodation_id references Accommodation.accommodation_id
    FOREIGN KEY (accommodation_id)
    REFERENCES Accommodation (accommodation_id)
    ON DELETE CASCADE -- If accommodation deleted, its images are deleted
    ON UPDATE CASCADE -- Update accommodation_id in AccommodationImage if it changes in Accommodation
);

-- Amenity Table
-- Stores available amenities (e.g., WiFi, Pool)
CREATE TABLE Amenity (
  amenity_id CHAR(36) NOT NULL, -- Primary Key
  name VARCHAR(100) NOT NULL UNIQUE, -- Name of the amenity (Unique name)
  description TEXT NULL, -- Optional description
  CONSTRAINT pk_amenity PRIMARY KEY (amenity_id) -- Primary Key constraint
);

-- AmenityAssignment Table (Junction Table)
-- Links Amenities to the Accommodations that offer them
CREATE TABLE AmenityAssignment (
  accommodation_id CHAR(36) NOT NULL, -- Foreign Key referencing Accommodation
  amenity_id CHAR(36) NOT NULL, -- Foreign Key referencing Amenity
  CONSTRAINT pk_amenityassignment PRIMARY KEY (accommodation_id, amenity_id), -- Composite Primary Key
  CONSTRAINT fk_amenityassignment_accommodation -- Foreign Key constraint to ensure accommodation_id references Accommodation.accommodation_id
    FOREIGN KEY (accommodation_id)
    REFERENCES Accommodation (accommodation_id)
    ON DELETE CASCADE -- If accommodation deleted, remove amenity links
    ON UPDATE CASCADE, -- Update accommodation_id in AmenityAssignment if it changes in Accommodation
  CONSTRAINT fk_amenityassignment_amenity -- Foreign Key constraint to ensure amenity_id references Amenity.amenity_id
    FOREIGN KEY (amenity_id)
    REFERENCES Amenity (amenity_id)
    ON DELETE CASCADE -- If amenity deleted, remove links from accommodations
    ON UPDATE CASCADE -- Update amenity_id in AmenityAssignment if it changes in Amenity
);

-- UserReferral Table
-- Tracks user referrals
CREATE TABLE UserReferral (
  referral_id CHAR(36) NOT NULL, -- Primary Key
  referrer_id CHAR(36) NOT NULL, -- Foreign Key referencing User (The user who referred)
  referred_id CHAR(36) NOT NULL, -- Foreign Key referencing User (The user who was referred)
  referral_code VARCHAR(100) NOT NULL UNIQUE, -- Unique code used for the referral
  referral_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date of the referral
  referral_expiry_date DATETIME NULL, -- Optional expiry date
  referral_status ENUM('pending', 'claimed', 'expired') NOT NULL DEFAULT 'pending', -- Status of the referral
  CONSTRAINT pk_userreferral PRIMARY KEY (referral_id), -- Primary Key constraint
  CONSTRAINT fk_userreferral_referrer -- Foreign Key constraint to ensure referrer_id references User.user_id
    FOREIGN KEY (referrer_id)
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If referrer is deleted, remove their referral records
    ON UPDATE CASCADE, -- Update referrer_id in UserReferral if it changes in User
  CONSTRAINT fk_userreferral_referred -- Foreign Key constraint to ensure referred_id references User.user_id
    FOREIGN KEY (referred_id)
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If referred user is deleted, remove the referral record
    ON UPDATE CASCADE -- Update referred_id in UserReferral if it changes in User
);

-- Message Table
-- Stores messages exchanged between users, potentially linked to bookings
CREATE TABLE Message (
  message_id CHAR(36) NOT NULL, -- Primary Key
  sender_id CHAR(36) NULL, -- Foreign Key referencing User
  recipient_id CHAR(36) NULL, -- Foreign Key referencing User
  booking_id CHAR(36) NULL, -- Optional Foreign Key linking to a booking
  content TEXT NOT NULL, -- The message content
  sent_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the message was sent
  CONSTRAINT pk_message PRIMARY KEY (message_id), -- Primary Key constraint
  CONSTRAINT fk_message_sender -- Foreign Key constraint to ensure sender_id references User.user_id
    FOREIGN KEY (sender_id)
    REFERENCES User (user_id)
    ON DELETE SET NULL -- If sender deleted, messages remain but sender is anonymized
    ON UPDATE CASCADE, -- If sender_id is updated, update all messages
  CONSTRAINT fk_message_recipient -- Foreign Key constraint to ensure recipient_id references User.user_id
    FOREIGN KEY (recipient_id)
    REFERENCES User (user_id)
    ON DELETE SET NULL -- If recipient deleted, messages remain but recipient is anonymized
    ON UPDATE CASCADE, -- If recipient_id is updated, update all messages
  CONSTRAINT fk_message_booking -- Foreign Key constraint to ensure booking_id references Booking.booking_id
    FOREIGN KEY (booking_id)
    REFERENCES Booking (booking_id)
    ON DELETE SET NULL -- If booking deleted, messages linked to it remain but are unlinked
    ON UPDATE CASCADE -- Update booking_id in Message if it changes in Booking
);

-- Payment Table
-- Stores payment transactions. Can be linked to bookings or referrals
CREATE TABLE Payment (
  payment_id CHAR(36) NOT NULL, -- Primary Key
  referral_id CHAR(36) NULL, -- Optional Foreign Key referencing UserReferral (Payment related to a referral bonus)
  booking_id CHAR(36) NOT NULL, -- Optional Foreign Key referencing Booking (Payment for a booking)
  amount DECIMAL(10,2) NOT NULL, -- Payment amount (Increased precision)
  payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date of the payment
  method VARCHAR(50) NOT NULL, -- Payment method
  payment_status ENUM('completed', 'pending', 'failed', 'refunded') NOT NULL DEFAULT 'pending', -- Payment status (Added refunded)
  CONSTRAINT pk_payment PRIMARY KEY (payment_id), -- Primary Key constraint
  CONSTRAINT fk_payment_booking -- Foreign Key constraint to ensure booking_id references Booking.booking_id
    FOREIGN KEY (booking_id)
    REFERENCES Booking (booking_id)
    ON DELETE CASCADE -- If booking deleted, remove the payment record
    ON UPDATE CASCADE, -- Update booking_id in Payment if it changes in Booking
  CONSTRAINT fk_payment_referral -- Foreign Key constraint to ensure referral_id references UserReferral.referral_id
    FOREIGN KEY (referral_id)
    REFERENCES UserReferral (referral_id)
    ON DELETE CASCADE -- If referral deleted, remove the payment record
    ON UPDATE CASCADE -- Update referral_id in Payment if it changes in UserReferral
);

-- SupportTicket Table
-- Stores support tickets raised by users
CREATE TABLE SupportTicket (
  ticket_id CHAR(36) NOT NULL, -- Primary Key
  user_id CHAR(36) NOT NULL, -- Foreign Key referencing User (User who created the ticket)
  assigned_admin_id CHAR(36) NULL, -- Optional Foreign Key referencing Admin (Admin assigned to the ticket) (Renamed from admin_id for clarity)
  subject VARCHAR(100) NOT NULL, -- Subject of the ticket
  description TEXT NOT NULL, -- Description of the issue
  status ENUM('open', 'in_progress', 'resolved', 'closed') NOT NULL DEFAULT 'open',
  creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the ticket was created
  update_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Auto-update on modification
  CONSTRAINT pk_supportticket PRIMARY KEY (ticket_id), -- Primary Key constraint
  CONSTRAINT fk_supportticket_user -- Foreign Key constraint to ensure user_id references User.user_id
    FOREIGN KEY (user_id)
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If user deleted, their support tickets are deleted
    ON UPDATE CASCADE, -- Update user_id in SupportTicket if it changes in User
  CONSTRAINT fk_supportticket_admin -- FK references the Admin table using the admin_id column
    FOREIGN KEY (assigned_admin_id)
    REFERENCES Admin (admin_id)
    ON DELETE SET NULL -- If assigned admin is deleted, unassign them from the ticket
    ON UPDATE CASCADE -- If admin_id is updated, update all tickets assigned to that admin
);

-- Notification Table
-- Stores notifications sent to users
CREATE TABLE Notification (
  notification_id CHAR(36) NOT NULL, -- Primary Key
  user_id CHAR(36) NOT NULL, -- Foreign Key referencing User (Recipient of the notification)
  notification_type ENUM('booking', 'message', 'review', 'referral', 'payment', 'system') NOT NULL, -- Type of notification (Added system)
  message TEXT NOT NULL, -- Content of the notification
  is_read BOOLEAN NOT NULL DEFAULT FALSE, -- Whether the user has read the notification
  notification_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the notification was created
  CONSTRAINT pk_notification PRIMARY KEY (notification_id),
  CONSTRAINT fk_notification_user -- Foreign Key constraint to ensure user_id references User.user_id
    FOREIGN KEY (user_id)
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If user deleted, their notifications are deleted
    ON UPDATE CASCADE -- Update user_id in Notification if it changes in User
);

-- BannedUser Table
-- Tracks users who have been banned
CREATE TABLE BannedUser (
  ban_id CHAR(36) NOT NULL, -- Primary Key
  user_id CHAR(36) NOT NULL UNIQUE, -- Foreign Key referencing User (The user who is banned) (Added UNIQUE as a user is usually banned only once)
  admin_id CHAR(36) NULL, -- Optional Foreign Key referencing Admin (Admin who issued the ban) (Made NULLable as maybe automated bans exist)
  ban_reason TEXT NULL, -- Optional reason for the ban (Made NULLable)
  ban_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the ban was issued
  unban_date DATETIME NULL, -- Optional date the ban expires or was lifted
  CONSTRAINT pk_banneduser PRIMARY KEY (ban_id), -- Primary Key constraint
  CONSTRAINT fk_banneduser_user -- Foreign Key constraint to ensure user_id references User.user_id
    FOREIGN KEY (user_id)
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If the banned user is deleted, the ban record is deleted
    ON UPDATE CASCADE, -- If user_id is updated, update all bans for that user
  CONSTRAINT fk_banneduser_admin -- Foreign Key constraint to ensure admin_id references Admin.admin_id
    FOREIGN KEY (admin_id)
    REFERENCES Admin (admin_id) -- FK references the Admin table using the admin_id column
    ON DELETE SET NULL -- If admin deleted, ban record remains but admin link is severed
    ON UPDATE CASCADE -- If admin_id is updated, update all bans issued by that admin
);

-- PlatformPolicy Table
-- Stores platform policies and terms
CREATE TABLE PlatformPolicy (
  policy_id CHAR(36) NOT NULL, -- Primary Key
  title VARCHAR(100) NOT NULL UNIQUE, -- Title of the policy
  content TEXT NOT NULL, -- Full text content of the policy (Renamed from description)
  created_by_admin_id CHAR(36) NULL, -- Optional Foreign Key referencing Admin (Admin who created the policy) (Made NULLable/Renamed)
  creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the policy was created
  last_update_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Date the policy was last updated
  CONSTRAINT pk_platformpolicy PRIMARY KEY (policy_id), -- Primary Key constraint
  CONSTRAINT fk_platformpolicy_admin -- FK references the Admin table using the admin_id column
    FOREIGN KEY (created_by_admin_id)
    REFERENCES Admin (admin_id)
    ON DELETE SET NULL -- If admin deleted, policy remains but link is severed
    ON UPDATE CASCADE -- If admin_id is updated, update all policies created by that admin
);



-- Insert User Data
INSERT INTO User (user_type, first_name, last_name, email, phone_number, password_hash, profile_picture, creation_date, last_login) VALUES
('admin', 'Maximilian', 'Mueller', 'maximilian.mueller@example.com', '01701234501', SHA2('safePassword41', 256), 'http://example.com/pic/maximilian_mueller.jpg', '2023-01-01 10:00:00', '2025-05-20 10:00:00'),
('admin', 'Sophie', 'Schmidt', 'sophie.schmidt@example.com', '01701234502', SHA2('safePassword42', 256), 'http://example.com/pic/sophie_schmidt.jpg', '2023-01-02 10:00:00', '2025-05-21 10:00:00'),
('admin', 'Alexander', 'Schneider', 'alexander.schneider@example.com', '01701234503', SHA2('safePassword43', 256), 'http://example.com/pic/alexander_schneider.jpg', '2023-01-03 10:00:00', '2025-05-22 10:00:00'),
('admin', 'Marie', 'Fischer', 'marie.fischer@example.com', '01701234504', SHA2('safePassword44', 256), 'http://example.com/pic/marie_fischer.jpg', '2023-01-04 10:00:00', '2025-05-23 10:00:00'),
('admin', 'Paul', 'Weber', 'paul.weber@example.com', '01701234505', SHA2('safePassword45', 256), 'http://example.com/pic/paul_weber.jpg', '2023-01-05 10:00:00', '2025-05-24 10:00:00'),
('admin', 'Emilia', 'Meyer', 'emilia.meyer@example.com', '01701234506', SHA2('safePassword46', 256), 'http://example.com/pic/emilia_meyer.jpg', '2023-01-06 10:00:00', '2025-05-25 10:00:00'),
('admin', 'Leon', 'Wagner', 'leon.wagner@example.com', '01701234507', SHA2('safePassword47', 256), 'http://example.com/pic/leon_wagner.jpg', '2023-01-07 10:00:00', '2025-05-26 10:00:00'),
('admin', 'Anna', 'Becker', 'anna.becker@example.com', '01701234508', SHA2('safePassword48', 256), 'http://example.com/pic/anna_becker.jpg', '2023-01-08 10:00:00', '2025-05-27 10:00:00'),
('admin', 'Felix', 'Schulz', 'felix.schulz@example.com', '01701234509', SHA2('safePassword49', 256), 'http://example.com/pic/felix_schulz.jpg', '2023-01-09 10:00:00', '2025-05-28 10:00:00'),
('admin', 'Mia', 'Hoffmann', 'mia.hoffmann@example.com', '01701234510', SHA2('safePassword50', 256), 'http://example.com/pic/mia_hoffmann.jpg', '2023-01-10 10:00:00', '2025-05-29 10:00:00'),
('admin', 'Lukas', 'Schaefer', 'lukas.schaefer@example.com', '01701234511', SHA2('safePassword51', 256), 'http://example.com/pic/lukas_schaefer.jpg', '2023-01-11 10:00:00', '2025-05-30 10:00:00'),
('admin', 'Lena', 'Koch', 'lena.koch@example.com', '01701234512', SHA2('safePassword52', 256), 'http://example.com/pic/lena_koch.jpg', '2023-01-12 10:00:00', '2025-05-31 10:00:00'),
('admin', 'Elias', 'Bauer', 'elias.bauer@example.com', '01701234513', SHA2('safePassword53', 256), 'http://example.com/pic/elias_bauer.jpg', '2023-01-13 10:00:00', '2025-06-01 10:00:00'),
('admin', 'Laura', 'Richter', 'laura.richter@example.com', '01701234514', SHA2('safePassword54', 256), 'http://example.com/pic/laura_richter.jpg', '2023-01-14 10:00:00', '2025-06-02 10:00:00'),
('admin', 'Jonas', 'Klein', 'jonas.klein@example.com', '01701234515', SHA2('safePassword55', 256), 'http://example.com/pic/jonas_klein.jpg', '2023-01-15 10:00:00', '2025-06-03 10:00:00'),
('admin', 'Hannah', 'Wolf', 'hannah.wolf@example.com', '01701234516', SHA2('safePassword56', 256), 'http://example.com/pic/hannah_wolf.jpg', '2023-01-16 10:00:00', '2025-06-04 10:00:00'),
('admin', 'Finn', 'Neumann', 'finn.neumann@example.com', '01701234517', SHA2('safePassword57', 256), 'http://example.com/pic/finn_neumann.jpg', '2023-01-17 10:00:00', '2025-06-05 10:00:00'),
('admin', 'Lara', 'Schwarz', 'lara.schwarz@example.com', '01701234518', SHA2('safePassword58', 256), 'http://example.com/pic/lara_schwarz.jpg', '2023-01-18 10:00:00', '2025-06-06 10:00:00'),
('admin', 'Luca', 'Zimmermann', 'luca.zimmermann@example.com', '01701234519', SHA2('safePassword59', 256), 'http://example.com/pic/luca_zimmermann.jpg', '2023-01-19 10:00:00', '2025-06-07 10:00:00'),
('admin', 'Sarah', 'Braun', 'sarah.braun@example.com', '01701234520', SHA2('safePassword60', 256), 'http://example.com/pic/sarah_braun.jpg', '2023-01-20 10:00:00', '2025-06-08 10:00:00'),
('guest', 'Niklas', 'Meier', 'niklas.meier@example.com', '01511234521', SHA2('safePassword1', 256), 'http://example.com/pic/niklas_meier.jpg', '2023-01-21 10:00:00', '2025-06-09 10:00:00'),
('guest', 'Charlotte', 'Hofmann', 'charlotte.hofmann@example.com', '01511234522', SHA2('safePassword2', 256), 'http://example.com/pic/charlotte_hofmann.jpg', '2023-01-22 10:00:00', '2025-06-10 10:00:00'),
('guest', 'Ben', 'Hartmann', 'ben.hartmann@example.com', '01511234523', SHA2('safePassword3', 256), 'http://example.com/pic/ben_hartmann.jpg', '2023-01-23 10:00:00', '2025-06-11 10:00:00'),
('guest', 'Johanna', 'Franke', 'johanna.franke@example.com', '01511234524', SHA2('safePassword4', 256), 'http://example.com/pic/johanna_franke.jpg', '2023-01-24 10:00:00', '2025-06-12 10:00:00'),
('guest', 'Tim', 'Walter', 'tim.walter@example.com', '01511234525', SHA2('safePassword5', 256), 'http://example.com/pic/tim_walter.jpg', '2023-01-25 10:00:00', '2025-06-13 10:00:00'),
('guest', 'Amelie', 'Peters', 'amelie.peters@example.com', '01511234526', SHA2('safePassword6', 256), 'http://example.com/pic/amelie_peters.jpg', '2023-01-26 10:00:00', '2025-06-14 10:00:00'),
('guest', 'Moritz', 'Kruse', 'moritz.kruse@example.com', '01511234527', SHA2('safePassword7', 256), 'http://example.com/pic/moritz_kruse.jpg', '2023-01-27 10:00:00', '2025-06-15 10:00:00'),
('guest', 'Clara', 'Brandt', 'clara.brandt@example.com', '01511234528', SHA2('safePassword8', 256), 'http://example.com/pic/clara_brandt.jpg', '2023-01-28 10:00:00', '2025-06-16 10:00:00'),
('guest', 'Noah', 'Schuster', 'noah.schuster@example.com', '01511234529', SHA2('safePassword9', 256), 'http://example.com/pic/noah_schuster.jpg', '2023-01-29 10:00:00', '2025-06-17 10:00:00'),
('guest', 'Luisa', 'Vogel', 'luisa.vogel@example.com', '01511234530', SHA2('safePassword10', 256), 'http://example.com/pic/luisa_vogel.jpg', '2023-01-30 10:00:00', '2025-06-18 10:00:00'),
('guest', 'Julian', 'Seidel', 'julian.seidel@example.com', '01511234531', SHA2('safePassword11', 256), 'http://example.com/pic/julian_seidel.jpg', '2023-01-31 10:00:00', '2025-06-19 10:00:00'),
('guest', 'Marieke', 'Hansen', 'marieke.hansen@example.com', '01511234532', SHA2('safePassword12', 256), 'http://example.com/pic/marieke_hansen.jpg', '2023-02-01 10:00:00', '2025-06-20 10:00:00'),
('guest', 'David', 'Lehmann', 'david.lehmann@example.com', '01511234533', SHA2('safePassword13', 256), 'http://example.com/pic/david_lehmann.jpg', '2023-02-02 10:00:00', '2025-06-21 10:00:00'),
('guest', 'Sophie', 'Koehler', 'sophie.koehler@example.com', '01511234534', SHA2('safePassword14', 256), 'http://example.com/pic/sophie_koehler.jpg', '2023-02-03 10:00:00', '2025-06-22 10:00:00'),
('guest', 'Emil', 'Bergmann', 'emil.bergmann@example.com', '01511234535', SHA2('safePassword15', 256), 'http://example.com/pic/emil_bergmann.jpg', '2023-02-04 10:00:00', '2025-06-23 10:00:00'),
('guest', 'Maja', 'Pohl', 'maja.pohl@example.com', '01511234536', SHA2('safePassword16', 256), 'http://example.com/pic/maja_pohl.jpg', '2023-02-05 10:00:00', '2025-06-24 10:00:00'),
('guest', 'Leo', 'Engel', 'leo.engel@example.com', '01511234537', SHA2('safePassword17', 256), 'http://example.com/pic/leo_engel.jpg', '2023-02-06 10:00:00', '2025-06-25 10:00:00'),
('guest', 'Lena', 'Mayer', 'lena.mayer@example.com', '01511234538', SHA2('safePassword18', 256), 'http://example.com/pic/lena_mayer.jpg', '2023-02-07 10:00:00', '2025-06-26 10:00:00'),
('guest', 'Erik', 'Winkler', 'erik.winkler@example.com', '01511234539', SHA2('safePassword19', 256), 'http://example.com/pic/erik_winkler.jpg', '2023-02-08 10:00:00', '2025-06-27 10:00:00'),
('guest', 'Nele', 'Gross', 'nele.gross@example.com', '01511234540', SHA2('safePassword20', 256), 'http://example.com/pic/nele_gross.jpg', '2023-02-09 10:00:00', '2025-06-28 10:00:00'),
('host', 'Max', 'Mustermann', 'max.mustermann@example.com', '01609876541', SHA2('safePassword21', 256), 'http://example.com/pic/max_mustermann.jpg', '2023-02-10 10:00:00', '2025-06-29 10:00:00'),
('host', 'Lena', 'Schmitt', 'lena.schmitt@example.com', '01609876542', SHA2('safePassword22', 256), 'http://example.com/pic/lena_schmitt.jpg', '2023-02-11 10:00:00', '2025-06-30 10:00:00'),
('host', 'Fabian', 'Huber', 'fabian.huber@example.com', '01609876543', SHA2('safePassword23', 256), 'http://example.com/pic/fabian_huber.jpg', '2023-02-12 10:00:00', '2025-07-01 10:00:00'),
('host', 'Julia', 'Wagner', 'julia.wagner@example.com', '01609876544', SHA2('safePassword24', 256), 'http://example.com/pic/julia_wagner.jpg', '2023-02-13 10:00:00', '2025-07-02 10:00:00'),
('host', 'Tom', 'Becker', 'tom.becker@example.com', '01609876545', SHA2('safePassword25', 256), 'http://example.com/pic/tom_becker.jpg', '2023-02-14 10:00:00', '2025-07-03 10:00:00'),
('host', 'Lea', 'Maier', 'lea.maier@example.com', '01609876546', SHA2('safePassword26', 256), 'http://example.com/pic/lea_maier.jpg', '2023-02-15 10:00:00', '2025-07-04 10:00:00'),
('host', 'Benno', 'Mueller', 'benno.mueller@example.com', '01609876547', SHA2('safePassword27', 256), 'http://example.com/pic/benno_mueller.jpg', '2023-02-16 10:00:00', '2025-07-05 10:00:00'),
('host', 'Hannah', 'Schmidt', 'hannah.schmidt@example.com', '01609876548', SHA2('safePassword28', 256), 'http://example.com/pic/hannah_schmidt.jpg', '2023-02-17 10:00:00', '2025-07-06 10:00:00'),
('host', 'Christian', 'Fischer', 'christian.fischer@example.com', '01609876549', SHA2('safePassword29', 256), 'http://example.com/pic/christian_fischer.jpg', '2023-02-18 10:00:00', '2025-07-07 10:00:00'),
('host', 'Emilia', 'Weber', 'emilia.weber@example.com', '01609876550', SHA2('safePassword30', 256), 'http://example.com/pic/emilia_weber.jpg', '2023-02-19 10:00:00', '2025-07-08 10:00:00'),
('host', 'Vincent', 'Meyer', 'vincent.meyer@example.com', '01609876551', SHA2('safePassword31', 256), 'http://example.com/pic/vincent_meyer.jpg', '2023-02-20 10:00:00', '2025-07-09 10:00:00'),
('host', 'Sophia', 'Wagner', 'sophia.wagner@example.com', '01609876552', SHA2('safePassword32', 256), 'http://example.com/pic/sophia_wagner.jpg', '2023-02-21 10:00:00', '2025-07-10 10:00:00'),
('host', 'Jannes', 'Koch', 'jannes.koch@example.com', '01609876553', SHA2('safePassword33', 256), 'http://example.com/pic/jannes_koch.jpg', '2023-02-22 10:00:00', '2025-07-11 10:00:00'),
('host', 'Alicia', 'Bauer', 'alicia.bauer@example.com', '01609876554', SHA2('safePassword34', 256), 'http://example.com/pic/alicia_bauer.jpg', '2023-02-23 10:00:00', '2025-07-12 10:00:00'),
('host', 'Niklas', 'Richter', 'niklas.richter@example.com', '01609876555', SHA2('safePassword35', 256), 'http://example.com/pic/niklas_richter.jpg', '2023-02-24 10:00:00', '2025-07-13 10:00:00'),
('host', 'Theresa', 'Klein', 'theresa.klein@example.com', '01609876556', SHA2('safePassword36', 256), 'http://example.com/pic/theresa_klein.jpg', '2023-02-25 10:00:00', '2025-07-14 10:00:00'),
('host', 'Johannes', 'Wolf', 'johannes.wolf@example.com', '01609876557', SHA2('safePassword37', 256), 'http://example.com/pic/johannes_wolf.jpg', '2023-02-26 10:00:00', '2025-07-15 10:00:00'),
('host', 'Frida', 'Neumann', 'frida.neumann@example.com', '01609876558', SHA2('safePassword38', 256), 'http://example.com/pic/frida_neumann.jpg', '2023-02-27 10:00:00', '2025-07-16 10:00:00'),
('host', 'Anton', 'Schwarz', 'anton.schwarz@example.com', '01609876559', SHA2('safePassword39', 256), 'http://example.com/pic/anton_schwarz.jpg', '2023-02-28 10:00:00', '2025-07-17 10:00:00'),
('host', 'Clara', 'Zimmermann', 'clara.zimmermann@example.com', '01609876560', SHA2('safePassword40', 256), 'http://example.com/pic/clara_zimmermann.jpg', '2023-03-01 10:00:00', '2025-07-18 10:00:00');

-- Insert Admin Data
INSERT INTO Admin (admin_id, role)
SELECT
  u.user_id, -- Use user_id from User table
  a.admin_role -- Use admin_role from the subquery
FROM User u
-- Use a subquery to define admin roles with email addresses
JOIN (
  SELECT 'maximilian.mueller@example.com' AS email, 'writer' AS admin_role
  UNION ALL SELECT 'sophie.schmidt@example.com', 'writer'
  UNION ALL SELECT 'alexander.schneider@example.com', 'writer'
  UNION ALL SELECT 'marie.fischer@example.com', 'writer'
  UNION ALL SELECT 'paul.weber@example.com', 'writer'
  UNION ALL SELECT 'emilia.meyer@example.com', 'writer'
  UNION ALL SELECT 'leon.wagner@example.com', 'reader'
  UNION ALL SELECT 'anna.becker@example.com', 'reader'
  UNION ALL SELECT 'felix.schulz@example.com', 'reader'
  UNION ALL SELECT 'mia.hoffmann@example.com', 'reader'
  UNION ALL SELECT 'lukas.schaefer@example.com', 'reader'
  UNION ALL SELECT 'lena.koch@example.com', 'reader'
  UNION ALL SELECT 'elias.bauer@example.com', 'reader'
  UNION ALL SELECT 'laura.richter@example.com', 'reader'
  UNION ALL SELECT 'jonas.klein@example.com', 'reader'
  UNION ALL SELECT 'hannah.wolf@example.com', 'reader'
  UNION ALL SELECT 'finn.neumann@example.com', 'reader'
  UNION ALL SELECT 'lara.schwarz@example.com', 'reader'
  UNION ALL SELECT 'luca.zimmermann@example.com', 'reader'
  UNION ALL SELECT 'sarah.braun@example.com', 'reader'
) a ON u.email = a.email AND u.user_type = 'admin'; -- Define the compound condition to match email and user_type

-- Insert Guest Data
INSERT INTO Guest (guest_id, membership_tier)
SELECT
  u.user_id, -- Use user_id from User table
  g.membership_tier -- Use membership_tier from the subquery
FROM User u
-- Use a subquery to define guest membership tiers with email addresses
JOIN (
  SELECT 'niklas.meier@example.com' AS email, 'free' AS membership_tier
  UNION ALL SELECT 'charlotte.hofmann@example.com', 'free'
  UNION ALL SELECT 'ben.hartmann@example.com', 'free'
  UNION ALL SELECT 'johanna.franke@example.com', 'free'
  UNION ALL SELECT 'tim.walter@example.com', 'free'
  UNION ALL SELECT 'amelie.peters@example.com', 'free'
  UNION ALL SELECT 'moritz.kruse@example.com', 'free'
  UNION ALL SELECT 'clara.brandt@example.com', 'free'
  UNION ALL SELECT 'noah.schuster@example.com', 'free'
  UNION ALL SELECT 'luisa.vogel@example.com', 'free'
  UNION ALL SELECT 'julian.seidel@example.com', 'free'
  UNION ALL SELECT 'marieke.hansen@example.com', 'free'
  UNION ALL SELECT 'david.lehmann@example.com', 'free'
  UNION ALL SELECT 'sophie.koehler@example.com', 'premium'
  UNION ALL SELECT 'emil.bergmann@example.com', 'premium'
  UNION ALL SELECT 'maja.pohl@example.com', 'premium'
  UNION ALL SELECT 'leo.engel@example.com', 'premium'
  UNION ALL SELECT 'lena.mayer@example.com', 'premium'
  UNION ALL SELECT 'erik.winkler@example.com', 'premium'
  UNION ALL SELECT 'nele.gross@example.com', 'premium'
) g ON u.email = g.email AND u.user_type = 'guest'; -- Define the compound condition to match email and user_type

-- Insert Host Data
INSERT INTO Host (host_id, host_tier)
SELECT
  u.user_id, -- Use user_id from User table
  h.host_tier -- Use host_tier from the subquery
FROM User u
-- Use a subquery to define host tiers with email addresses
JOIN (
  SELECT 'max.mustermann@example.com' AS email, 'prime' AS host_tier
  UNION ALL SELECT 'lena.schmitt@example.com', 'prime'
  UNION ALL SELECT 'fabian.huber@example.com', 'prime'
  UNION ALL SELECT 'julia.wagner@example.com', 'prime'
  UNION ALL SELECT 'tom.becker@example.com', 'prime'
  UNION ALL SELECT 'lea.maier@example.com', 'prime'
  UNION ALL SELECT 'benno.mueller@example.com', 'prime'
  UNION ALL SELECT 'hannah.schmidt@example.com', 'prime'
  UNION ALL SELECT 'christian.fischer@example.com', 'regular'
  UNION ALL SELECT 'emilia.weber@example.com', 'regular'
  UNION ALL SELECT 'vincent.meyer@example.com', 'regular'
  UNION ALL SELECT 'sophia.wagner@example.com', 'regular'
  UNION ALL SELECT 'jannes.koch@example.com', 'regular'
  UNION ALL SELECT 'alicia.bauer@example.com', 'regular'
  UNION ALL SELECT 'niklas.richter@example.com', 'regular'
  UNION ALL SELECT 'theresa.klein@example.com', 'regular'
  UNION ALL SELECT 'johannes.wolf@example.com', 'regular'
  UNION ALL SELECT 'frida.neumann@example.com', 'regular'
  UNION ALL SELECT 'anton.schwarz@example.com', 'regular'
  UNION ALL SELECT 'clara.zimmermann@example.com', 'regular'
) h ON u.email = h.email AND u.user_type = 'host'; -- Define the compound condition to match email and user_type

-- Insert Property Data
INSERT INTO Property (title, country, state, zip_code, address, square_feet, property_type) VALUES
('Modern Apartment in Berlin Mitte', 'Germany', 'Berlin', '10115', 'Invalidenstrasse 43, Berlin', 850, 'Apartment'),
('Charming House near Munich', 'Germany', 'Bavaria', '80331', 'Sendlinger Strasse 25, Muenchen', 2200, 'House'),
('Luxury Penthouse in Hamburg', 'Germany', 'Hamburg', '20095', 'Spitalerstrasse 10, Hamburg', 1500, 'Penthouse'),
('Office Space in Frankfurt am Main', 'Germany', 'Hesse', '60311', 'Zeil 90, Frankfurt am Main', 3000, 'Commercial'),
('Rustic Cottage in Black Forest', 'Germany', 'Baden-Wuerttemberg', '79822', 'Feldbergstrasse 2, Titisee-Neustadt', 1200, 'Cottage'),
('Student Studio in Leipzig', 'Germany', 'Saxony', '04109', 'Karl-Liebknecht-Strasse 50, Leipzig', 400, 'Studio'),
('Warehouse near Düsseldorf', 'Germany', 'North Rhine-Westphalia', '40210', 'Graf-Adolf-Strasse 12, Duesseldorf', 5000, 'Industrial'),
('Historic Villa in Dresden', 'Germany', 'Saxony', '01067', 'Koenigstrasse 8, Dresden', 3500, 'Villa'),
('Countryside Home in Lower Saxony', 'Germany', 'Lower Saxony', '30159', 'Bahnhofstrasse 18, Hannover', 1800, 'House'),
('Modern Flat in Stuttgart Center', 'Germany', 'Baden-Wuerttemberg', '70173', 'Koenigstrasse 45, Stuttgart', 950, 'Flat'),
('Alpine Chalet in Garmisch', 'Germany', 'Bavaria', '82467', 'Zugspitzstrasse 1, Garmisch-Partenkirchen', 1600, 'Chalet'),
('Seaside Bungalow in Kiel', 'Germany', 'Schleswig-Holstein', '24103', 'Kaistrasse 16, Kiel', 1100, 'Bungalow'),
('Loft Apartment in Cologne', 'Germany', 'North Rhine-Westphalia', '50667', 'Ehrenstrasse 22, Koeln', 1000, 'Loft'),
('Townhouse in Mainz Old Town', 'Germany', 'Rhineland-Palatinate', '55116', 'Augustinerstrasse 10, Mainz', 1300, 'Townhouse'),
('Penthouse in Freiburg', 'Germany', 'Baden-Wuerttemberg', '79098', 'Greiffeneggring 12, Freiburg', 350, 'Penthouse'),
('Villa near Bremen', 'Germany', 'Bremen', '28195', 'Weserstrasse 5, Bremen', 1400, 'Villa'),
('Skyscraper Office in Stuttgart', 'Germany', 'Baden-Wuerttemberg', '70174', 'Rotebuehlstrasse 60, Stuttgart', 8000, 'Commercial'),
('Lakeview Cabin in Bavaria', 'Germany', 'Bavaria', '83209', 'Seestrasse 18, Prien am Chiemsee', 900, 'Cabin'),
('Art Deco Flat in Nuremberg', 'Germany', 'Bavaria', '90402', 'Koenigstrasse 1, Nuernberg', 850, 'Flat'),
('Luxury Mansion in Wiesbaden', 'Germany', 'Hesse', '65183', 'Wilhelmstrasse 34, Wiesbaden', 6000, 'Mansion');

-- Insert PropertyAccess Data
INSERT INTO PropertyAccess (host_id, property_id)
SELECT
  h.host_id,
  p.property_id
FROM User h
JOIN 

-- Insert CancellationPolicy Data
INSERT INTO CancellationPolicy (name, description) VALUES
('Flexible - 1 Day', 'Guests can cancel up to 1 day before check-in for a full refund. No refund for later cancellations.'),
('Flexible - Same Day', 'Guests can cancel anytime before the day of check-in for a full refund.'),
('Moderate - 3 Days', 'Guests can cancel up to 3 days before check-in for a full refund. 50% refund if canceled within 3 days.'),
('Moderate - 5 Days', 'Guests can cancel up to 5 days before check-in for a full refund. 50% refund within 5 days.'),
('Strict - 7 Days', 'Guests can cancel up to 7 days before check-in for a 50% refund. No refund for cancellations within 7 days.'),
('Strict - 14 Days', 'Guests can cancel up to 14 days before check-in for a 50% refund. No refund for cancellations within 14 days.'),
('Non-refundable', 'Guests receive no refund, regardless of cancellation time.'),
('Fully Refundable - 48h After Booking', 'Guests can cancel within 48 hours of booking for a full refund, if the check-in date is at least 14 days away.'),
('Custom Host Policy', 'Custom cancellation terms provided by the host. May vary by property.'),
('Business Traveler Policy', 'Full refund up to 24 hours before check-in for business bookings with verified documents.'),
('Event Cancellation Protection', 'Full refund if the guest can prove a canceled event (e.g., trade fair, conference).'),
('Weather Guarantee', 'Full refund if extreme weather prevents travel. Must provide documentation.'),
('Force Majeure', 'Cancellations due to force majeure (e.g. natural disasters, war, pandemic) are fully refundable.'),
('Check-in Day Flex', '50% refund if canceled before 12:00 on the day of check-in. No refund after.'),
('Refund with Rebooking', 'Full refund if the guest rebooks another property within 30 days of cancellation.'),
('Medical Emergency Waiver', 'Full refund if cancellation is due to medical emergency, with proof.'),
('Last-Minute Grace', 'Full refund if canceled within 2 hours of booking and at least 48 hours before check-in.'),
('Holiday Period Strict', 'No refund for holiday bookings (e.g., Christmas, Easter). Exceptions only for emergencies.'),
('Tiered Refund Policy', '75% refund up to 10 days before check-in, 50% up to 5 days, none afterward.'),
('Stay Interrupted', 'Pro-rated refund if stay is cut short due to verifiable issues (e.g., heating failure).');

