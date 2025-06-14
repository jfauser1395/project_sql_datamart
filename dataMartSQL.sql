-- This SQL script creates a database schema for an AirBnB-like application.
-- All primary keys are typed CHAR(36) for UUIDs these are generated with UUID() function.


-- Create a new database
CREATE DATABASE IF NOT EXISTS Airbnb_like_DB;

-- Use the newly created database
USE Airbnb_like_DB;


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
  phone_number VARCHAR(50) NULL, -- Phone number is optional
  password_hash VARCHAR(255) NOT NULL UNIQUE, -- Stores the hashed password
  profile_picture VARCHAR(255) NOT NULL, -- URL or path to profile picture
  creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Automatically set on creation
  last_login TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Updates when the record is modified, can be used to track last login
  CONSTRAINT pk_user_id PRIMARY KEY (user_id) -- Primary Key constraint
);

-- Subclass Table: Admin
-- Stores attributes specific to Admin users.
-- user_id is both the Primary Key and a Foreign Key referencing User.user_id
CREATE TABLE Administrator (
  admin_id CHAR(36) NOT NULL, -- References User.user_id
  admin_role ENUM('reader', 'writer') NOT NULL DEFAULT 'reader', -- Admin-specific role
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

-- UserReferral Table
-- Tracks user referrals
CREATE TABLE UserReferral (
  referral_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
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

-- Indexes for UserReferral Table
-- These indexes can help speed up queries filtering by referrer or referred user
CREATE INDEX idx_referral_referrer ON UserReferral(referrer_id);
CREATE INDEX idx_referral_referred ON UserReferral(referred_id);

-- BannedUser Table
-- Tracks users who have been banned
CREATE TABLE BannedUser (
  ban_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  user_id CHAR(36) NOT NULL UNIQUE, -- Foreign Key referencing User (The user who is banned) (Added UNIQUE as a user is usually banned only once)
  admin_id CHAR(36) NULL, -- Optional Foreign Key referencing Admin (Admin who issued the ban) (Made NULLable as maybe automated bans exist)
  ban_reason TEXT NOT NULL, -- Optional reason for the ban
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
    REFERENCES Administrator (admin_id) -- FK references the Admin table using the admin_id column
    ON DELETE SET NULL -- If admin deleted, ban record remains but admin link is severed
    ON UPDATE CASCADE -- If admin_id is updated, update all bans issued by that admin
);

-- PropertyType Table
-- Stores different types of properties (e.g., Apartment, House)
CREATE TABLE PropertyType (
  property_type_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  property_type_name VARCHAR(30) NOT NULL UNIQUE, -- Name of the property type (Unique name)
  property_type_description TEXT NULL, -- Optional description of the property type
  CONSTRAINT pk_property_type PRIMARY KEY (property_type_id) -- Primary Key constraint
);

-- Property Table
-- Stores general details about a physical property
CREATE TABLE Property (
  property_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  property_type_id CHAR(36) NOT NULL, -- Foreign Key referencing PropertyType (Property belongs to a type)
  title VARCHAR(100) NOT NULL, -- Title of the property
  country VARCHAR(100) NOT NULL, -- Country where the property is located
  region VARCHAR(100) NOT NULL, -- State/Region where the property is located
  zip_code VARCHAR(50) NOT NULL, -- Zip/Postal code
  property_address VARCHAR(255) NOT NULL, -- Full address of the property
  square_feet INT NOT NULL, -- Size of the property in square feet
  CONSTRAINT pk_property PRIMARY KEY (property_id), -- Primary Key constraint
  CONSTRAINT fk_prop_type -- Foreign Key constraint to ensure property_type_id references PropertyType.property_type_id
    FOREIGN KEY (property_type_id)
    REFERENCES PropertyType (property_type_id)
    ON DELETE CASCADE -- If property type is deleted, remove all properties of that type
    ON UPDATE CASCADE -- Update property_type_id in Property if it changes in PropertyType
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
  policy_name VARCHAR(100) NOT NULL UNIQUE, -- Name of the policy (Unique name)
  policy_description TEXT NOT NULL, -- Description of the policy
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
  unit_description TEXT NOT NULL, -- unit description of the accommodation
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

-- AccommodationImage Table
-- Stores images associated with an Accommodation
CREATE TABLE AccommodationImage (
  image_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  accommodation_id CHAR(36) NOT NULL, -- Foreign Key referencing Accommodation
  image_url VARCHAR(255) NOT NULL UNIQUE, -- URL of the image
  image_description TEXT NULL, -- Optional description of the image
  display_order INT NOT NULL, -- Order to display the image
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
  amenity_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  amenity_name VARCHAR(100) NOT NULL UNIQUE, -- Name of the amenity (Unique name)
  amenity_description TEXT NULL, -- Optional description
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

-- Wishlist Table
-- Stores wishlists created by guests
CREATE TABLE Wishlist (
  wishlist_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  guest_id CHAR(36) NOT NULL, -- Foreign Key referencing Guest (A wishlist belongs to a guest)
  wishlist_title VARCHAR(100) NOT NULL, -- Title of the wishlist
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

-- Booking Table
-- Stores details about property bookings
CREATE TABLE Booking (
  booking_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  guest_id CHAR(36) NOT NULL, -- Foreign Key referencing Guest.guest_id
  accommodation_id CHAR(36) NOT NULL, -- Foreign Key referencing Accommodation.accommodation_id
  check_in_date DATETIME NOT NULL, -- Start date of the booking
  check_out_date DATETIME NOT NULL, -- End date of the booking
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
  CONSTRAINT chk_booking_dates CHECK (check_in_date < check_out_date) -- Ensure end date is after start date
);

-- Indexes for Booking Table
-- These indexes can help speed up queries filtering by guest, accommodation, or date ranges
CREATE INDEX idx_booking_guest ON Booking(guest_id);
CREATE INDEX idx_booking_accommodation ON Booking(accommodation_id);
CREATE INDEX idx_booking_dates ON Booking(check_in_date, check_out_date);

-- Review Table
-- Stores reviews left by users about other users or properties/accommodations
CREATE TABLE Review (
  review_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  reviewer_id CHAR(36) NOT NULL, -- Foreign Key referencing User (the user writing the review)
  reviewee_id CHAR(36) NOT NULL, -- Foreign Key referencing User (the user being reviewed - e.g., host)
  booking_id CHAR(36) NOT NULL, -- Foreign Key referencing Booking
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
    ON DELETE CASCADE -- If booking deleted, remove the review
    ON UPDATE CASCADE, -- Update booking_id in Review if it changes in Booking
  CONSTRAINT chk_review_rating CHECK (rating >= 1 AND rating <= 5) -- Ensure rating is within a valid range
);

-- Indexes for Review Table
-- These indexes can help speed up queries filtering by reviewer, reviewee, or booking
CREATE INDEX idx_review_reviewee ON Review(reviewee_id);
CREATE INDEX idx_review_booking ON Review(booking_id);

-- UserMessage Table
-- Stores messages exchanged between users, potentially linked to bookings
CREATE TABLE UserMessage (
  message_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  sender_id CHAR(36) NULL, -- Foreign Key referencing User
  recipient_id CHAR(36) NULL, -- Foreign Key referencing User
  booking_id CHAR(36) DEFAULT NULL, -- Optional Foreign Key linking to a booking
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

-- PaymentMethod table
-- Stores different payment methods available for payouts
CREATE TABLE PaymentMethod (
  payment_method_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  payment_name VARCHAR(20) UNIQUE, -- Method of payment (e.g., bank transfer, PayPal)
  CONSTRAINT pk_method PRIMARY KEY (payment_method_id) -- Primary Key constraint
);

-- Payout Table
-- Stores records of payouts made to hosts
CREATE TABLE Payout (
  payout_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  payment_method_id CHAR(36) NOT NULL, -- Method of payout (e.g., bank transfer, PayPal)
  host_id CHAR(36) NOT NULL, -- Foreign Key referencing Host (Payout is made to a host)
  amount DECIMAL(10,2) NOT NULL, -- Payout amount (Increased precision)
  payout_status ENUM('pending', 'completed', 'failed') NOT NULL DEFAULT 'pending', -- Payout status
  payout_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the payout was initiated/processed
  CONSTRAINT pk_payout PRIMARY KEY (payout_id), -- Primary Key constraint
  CONSTRAINT fk_payout_host -- Foreign Key constraint to ensure host_id references Host.host_id
    FOREIGN KEY (host_id)
    REFERENCES Host (host_id)
    ON DELETE RESTRICT -- Prevent deleting a host if they have payout records
    ON UPDATE CASCADE, -- Update host_id in Payout if it changes in Host
  CONSTRAINT fk_payout_method -- Foreign Key constraint to ensure payment_method_id references PaymentMethod.payment_method_id
    FOREIGN KEY (payment_method_id)
    REFERENCES PaymentMethod (payment_method_id)
    ON DELETE CASCADE -- If payment method deleted, remove all payouts using it
    ON UPDATE CASCADE, -- Update payment_method_id in Payout if it changes in PaymentMethod
  CONSTRAINT chk_payout_amount CHECK (amount >= 0) -- Ensure amount is not negative
);

-- Payment Table
-- Stores payment transactions. Can be linked to bookings or referrals
CREATE TABLE Payment (
  payment_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  payment_method_id CHAR(36) NOT NULL, -- Method of payout (e.g., bank transfer, PayPal)
  referral_id CHAR(36) NULL, -- Optional Foreign Key referencing UserReferral (Payment related to a referral bonus)
  booking_id CHAR(36) NOT NULL, -- Optional Foreign Key referencing Booking (Payment for a booking)
  amount DECIMAL(10,2) NOT NULL, -- Payment amount (Increased precision)
  payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date of the payment
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
    ON UPDATE CASCADE, -- Update referral_id in Payment if it changes in UserReferral
  CONSTRAINT fk_pay_method -- Foreign Key constraint to ensure payment_method_id references PaymentMethod.payment_method_id
    FOREIGN KEY (payment_method_id)
    REFERENCES PaymentMethod (payment_method_id)
    ON DELETE CASCADE -- If payment method deleted, remove all payouts using it
    ON UPDATE CASCADE -- Update payment_method_id in Payout if it changes in PaymentMethod
);

-- Indexes for Payment Table
-- These indexes can help speed up queries filtering by referral, booking, or status
CREATE INDEX idx_payment_booking ON Payment(booking_id);
CREATE INDEX idx_payment_status ON Payment(payment_status);

-- SupportTicket Table
-- Stores support tickets raised by users
CREATE TABLE SupportTicket (
  ticket_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  user_id CHAR(36) NOT NULL, -- Foreign Key referencing User (User who created the ticket)
  assigned_admin_id CHAR(36) NULL, -- Optional Foreign Key referencing Admin (Admin assigned to the ticket)
  ticket_subject VARCHAR(100) NOT NULL, -- Subject of the ticket
  ticket_description TEXT NOT NULL, -- Description of the issue
  ticket_status ENUM('open', 'in_progress', 'resolved', 'closed') NOT NULL DEFAULT 'open',
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
    REFERENCES Administrator (admin_id)
    ON DELETE SET NULL -- If assigned admin is deleted, unassign them from the ticket
    ON UPDATE CASCADE -- If admin_id is updated, update all tickets assigned to that admin
);

-- Notification Table
-- Stores notifications sent to users
CREATE TABLE AppNotification (
  notification_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  user_id CHAR(36) NOT NULL, -- Foreign Key referencing User (Recipient of the notification)
  notification_type ENUM('booking', 'message', 'review', 'referral', 'payment', 'system', 'promotion') NOT NULL, -- Type of notification
  notification_message TEXT NOT NULL, -- Content of the notification
  is_read BOOLEAN NOT NULL DEFAULT FALSE, -- Whether the user has read the notification
  notification_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the notification was created
  CONSTRAINT pk_notification PRIMARY KEY (notification_id),
  CONSTRAINT fk_notification_user -- Foreign Key constraint to ensure user_id references User.user_id
    FOREIGN KEY (user_id)
    REFERENCES User (user_id)
    ON DELETE CASCADE -- If user deleted, their notifications are deleted
    ON UPDATE CASCADE -- Update user_id in Notification if it changes in User
);

-- PlatformPolicy Table
-- Stores platform policies and terms
CREATE TABLE PlatformPolicy (
  policy_id CHAR(36) NOT NULL DEFAULT (UUID()), -- Primary Key
  created_by_admin_id CHAR(36) NULL, -- Optional Foreign Key referencing Admin (Admin who created the policy)
  title VARCHAR(100) NOT NULL UNIQUE, -- Title of the policy
  content TEXT NOT NULL, -- Full text content of the policy
  creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Date the policy was created
  last_update_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Date the policy was last updated
  CONSTRAINT pk_platformpolicy PRIMARY KEY (policy_id), -- Primary Key constraint
  CONSTRAINT fk_platformpolicy_admin -- FK references the Admin table using the admin_id column
    FOREIGN KEY (created_by_admin_id)
    REFERENCES Administrator (admin_id)
    ON DELETE SET NULL -- If admin deleted, policy remains but link is severed
    ON UPDATE CASCADE -- If admin_id is updated, update all policies created by that admin
);


-- Insert User Data
INSERT INTO User (user_type, first_name, last_name, email, phone_number, password_hash, profile_picture, creation_date, last_login) 
  VALUES
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
  ('host', 'Clara', 'Zimmermann', 'clara.zimmermann@example.com', '01609876560', SHA2('safePassword40', 256), 'http://example.com/pic/clara_zimmermann.jpg', '2023-03-01 10:00:00', '2025-07-18 10:00:00'),
  ('guest', 'Tobias', 'Keller', 'tobias.keller@example.com', '01511234541', SHA2('safePassword61', 256), 'http://example.com/pic/tobias_keller.jpg', '2023-02-10 10:00:00', '2025-06-29 10:00:00'),
  ('guest', 'Christina', 'Simon', 'christina.simon@example.com', '01511234542', SHA2('safePassword62', 256), 'http://example.com/pic/christina_simon.jpg', '2023-02-11 10:00:00', '2025-06-30 10:00:00'),
  ('guest', 'Michael', 'Fuchs', 'michael.fuchs@example.com', '01511234543', SHA2('safePassword63', 256), 'http://example.com/pic/michael_fuchs.jpg', '2023-02-12 10:00:00', '2025-07-01 10:00:00'),
  ('guest', 'Katharina', 'Herrmann', 'katharina.herrmann@example.com', '01511234544', SHA2('safePassword64', 256), 'http://example.com/pic/katharina_herrmann.jpg', '2023-02-13 10:00:00', '2025-07-02 10:00:00'),
  ('guest', 'Florian', 'Lange', 'florian.lange@example.com', '01511234545', SHA2('safePassword65', 256), 'http://example.com/pic/florian_lange.jpg', '2023-02-14 10:00:00', '2025-07-03 10:00:00'),
  ('guest', 'Vanessa', 'Busch', 'vanessa.busch@example.com', '01511234546', SHA2('safePassword66', 256), 'http://example.com/pic/vanessa_busch.jpg', '2023-02-15 10:00:00', '2025-07-04 10:00:00'),
  ('guest', 'Daniel', 'Kuhn', 'daniel.kuhn@example.com', '01511234547', SHA2('safePassword67', 256), 'http://example.com/pic/daniel_kuhn.jpg', '2023-02-16 10:00:00', '2025-07-05 10:00:00'),
  ('guest', 'Kristin', 'Jansen', 'kristin.jansen@example.com', '01511234548', SHA2('safePassword68', 256), 'http://example.com/pic/kristin_jansen.jpg', '2023-02-17 10:00:00', '2025-07-06 10:00:00'),
  ('guest', 'Philipp', 'Winter', 'philipp.winter@example.com', '01511234549', SHA2('safePassword69', 256), 'http://example.com/pic/philipp_winter.jpg', '2023-02-18 10:00:00', '2025-07-07 10:00:00'),
  ('guest', 'Jana', 'Schulte', 'jana.schulte@example.com', '01511234550', SHA2('safePassword70', 256), 'http://example.com/pic/jana_schulte.jpg', '2023-02-19 10:00:00', '2025-07-08 10:00:00'),
  ('guest', 'Matthias', 'Koenig', 'matthias.koenig@example.com', '01511234551', SHA2('safePassword71', 256), 'http://example.com/pic/matthias_koenig.jpg', '2023-02-20 10:00:00', '2025-07-09 10:00:00'),
  ('guest', 'Susanne', 'Albrecht', 'susanne.albrecht@example.com', '01511234552', SHA2('safePassword72', 256), 'http://example.com/pic/susanne_albrecht.jpg', '2023-02-21 10:00:00', '2025-07-10 10:00:00'),
  ('guest', 'Markus', 'Graf', 'markus.graf@example.com', '01511234553', SHA2('safePassword73', 256), 'http://example.com/pic/markus_graf.jpg', '2023-02-22 10:00:00', '2025-07-11 10:00:00'),
  ('guest', 'Nadine', 'Wild', 'nadine.wild@example.com', '01511234554', SHA2('safePassword74', 256), 'http://example.com/pic/nadine_wild.jpg', '2023-02-23 10:00:00', '2025-07-12 10:00:00'),
  ('guest', 'Stefan', 'Brand', 'stefan.brand@example.com', '01511234555', SHA2('safePassword75', 256), 'http://example.com/pic/stefan_brand.jpg', '2023-02-24 10:00:00', '2025-07-13 10:00:00'),
  ('guest', 'Patricia', 'Reich', 'patricia.reich@example.com', '01511234556', SHA2('safePassword76', 256), 'http://example.com/pic/patricia_reich.jpg', '2023-02-25 10:00:00', '2025-07-14 10:00:00'),
  ('guest', 'Simon', 'Arnold', 'simon.arnold@example.com', '01511234557', SHA2('safePassword77', 256), 'http://example.com/pic/simon_arnold.jpg', '2023-02-26 10:00:00', '2025-07-15 10:00:00'),
  ('guest', 'Christine', 'Vogt', 'christine.vogt@example.com', '01511234558', SHA2('safePassword78', 256), 'http://example.com/pic/christine_vogt.jpg', '2023-02-27 10:00:00', '2025-07-16 10:00:00'),
  ('guest', 'Andreas', 'Ott', 'andreas.ott@example.com', '01511234559', SHA2('safePassword79', 256), 'http://example.com/pic/andreas_ott.jpg', '2023-02-28 10:00:00', '2025-07-17 10:00:00'),
  ('guest', 'Julia', 'Krueger', 'julia.krueger@example.com', '01511234560', SHA2('safePassword80', 256), 'http://example.com/pic/julia_krueger.jpg', '2023-03-01 10:00:00', '2025-07-18 10:00:00')
;

-- Insert Admin Data
INSERT INTO Administrator (admin_id, admin_role)
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
  ) a ON u.email = a.email AND u.user_type = 'admin'
; -- Define the compound condition to match email and user_type

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
  ) g ON u.email = g.email AND u.user_type = 'guest'
; -- Define the compound condition to match email and user_type

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
  ) h ON u.email = h.email AND u.user_type = 'host'
; -- Define the compound condition to match email and user_type

-- Insert UserReferral Data
INSERT INTO UserReferral (referrer_id, referred_id, referral_code, referral_date, referral_expiry_date, referral_status)
VALUES
  ((SELECT user_id FROM User WHERE email = 'moritz.kruse@example.com'),
   (SELECT user_id FROM User WHERE email = 'luisa.vogel@example.com'),
   '684932', '2023-03-15 14:30:00', '2023-06-15 14:30:00', 'claimed'),
  
  ((SELECT user_id FROM User WHERE email = 'charlotte.hofmann@example.com'),
   (SELECT user_id FROM User WHERE email = 'tim.walter@example.com'),
   '217845', '2023-04-02 09:15:00', '2023-07-02 09:15:00', 'claimed'),
  
  ((SELECT user_id FROM User WHERE email = 'ben.hartmann@example.com'),
   (SELECT user_id FROM User WHERE email = 'johanna.franke@example.com'),
   '539761', '2023-04-18 16:45:00', '2023-07-18 16:45:00', 'expired'),
  
  ((SELECT user_id FROM User WHERE email = 'amelie.peters@example.com'),
   (SELECT user_id FROM User WHERE email = 'noah.schuster@example.com'),
   '892345', '2023-05-05 11:20:00', '2023-08-05 11:20:00', 'claimed'),
  
  ((SELECT user_id FROM User WHERE email = 'clara.brandt@example.com'),
   (SELECT user_id FROM User WHERE email = 'julian.seidel@example.com'),
   '456123', '2023-05-22 13:10:00', '2023-08-22 13:10:00', 'pending'),
  
  ((SELECT user_id FROM User WHERE email = 'david.lehmann@example.com'),
   (SELECT user_id FROM User WHERE email = 'marieke.hansen@example.com'),
   '789012', '2023-06-10 10:50:00', '2023-09-10 10:50:00', 'claimed'),
  
  ((SELECT user_id FROM User WHERE email = 'sophie.koehler@example.com'),
   (SELECT user_id FROM User WHERE email = 'emil.bergmann@example.com'),
   '345678', '2023-06-28 15:30:00', '2023-09-28 15:30:00', 'expired'),
  
  ((SELECT user_id FROM User WHERE email = 'maja.pohl@example.com'),
   (SELECT user_id FROM User WHERE email = 'leo.engel@example.com'),
   '901234', '2023-07-15 12:00:00', '2023-10-15 12:00:00', 'claimed'),
  
  ((SELECT user_id FROM User WHERE email = 'lena.mayer@example.com'),
   (SELECT user_id FROM User WHERE email = 'erik.winkler@example.com'),
   '567890', '2023-08-01 08:45:00', '2023-11-01 08:45:00', 'pending'),
  
  ((SELECT user_id FROM User WHERE email = 'nele.gross@example.com'),
   (SELECT user_id FROM User WHERE email = 'tobias.keller@example.com'),
   '123456', '2023-08-20 17:20:00', '2023-11-20 17:20:00', 'claimed'),
  
  ((SELECT user_id FROM User WHERE email = 'christina.simon@example.com'),
   (SELECT user_id FROM User WHERE email = 'michael.fuchs@example.com'),
   '234567', '2023-09-05 14:15:00', '2023-12-05 14:15:00', 'pending'),
  
  ((SELECT user_id FROM User WHERE email = 'katharina.herrmann@example.com'),
   (SELECT user_id FROM User WHERE email = 'florian.lange@example.com'),
   '890123', '2023-09-22 10:30:00', '2023-12-22 10:30:00', 'claimed'),
  
  ((SELECT user_id FROM User WHERE email = 'vanessa.busch@example.com'),
   (SELECT user_id FROM User WHERE email = 'daniel.kuhn@example.com'),
   '456789', '2023-10-10 09:00:00', '2024-01-10 09:00:00', 'expired'),
  
  ((SELECT user_id FROM User WHERE email = 'kristin.jansen@example.com'),
   (SELECT user_id FROM User WHERE email = 'philipp.winter@example.com'),
   '012345', '2023-10-28 16:40:00', '2024-01-28 16:40:00', 'claimed'),
  
  ((SELECT user_id FROM User WHERE email = 'jana.schulte@example.com'),
   (SELECT user_id FROM User WHERE email = 'matthias.koenig@example.com'),
   '678901', '2023-11-15 11:25:00', '2024-02-15 11:25:00', 'pending'),
  
  ((SELECT user_id FROM User WHERE email = 'susanne.albrecht@example.com'),
   (SELECT user_id FROM User WHERE email = 'markus.graf@example.com'),
   '345012', '2023-12-03 13:50:00', '2024-03-03 13:50:00', 'claimed'),
  
  ((SELECT user_id FROM User WHERE email = 'nadine.wild@example.com'),
   (SELECT user_id FROM User WHERE email = 'stefan.brand@example.com'),
   '789456', '2023-12-20 10:15:00', '2024-03-20 10:15:00', 'expired'),
  
  ((SELECT user_id FROM User WHERE email = 'patricia.reich@example.com'),
   (SELECT user_id FROM User WHERE email = 'simon.arnold@example.com'),
   '123789', '2024-01-07 15:30:00', '2024-04-07 15:30:00', 'claimed'),
  
  ((SELECT user_id FROM User WHERE email = 'christine.vogt@example.com'),
   (SELECT user_id FROM User WHERE email = 'andreas.ott@example.com'),
   '456012', '2024-01-25 09:45:00', '2024-04-25 09:45:00', 'pending'),
  
  ((SELECT user_id FROM User WHERE email = 'julia.krueger@example.com'),
   (SELECT user_id FROM User WHERE email = 'niklas.meier@example.com'),
   '890456', '2024-02-12 14:20:00', '2024-05-12 14:20:00', 'claimed')
;

-- Insert BannedUser Data
INSERT INTO BannedUser (user_id, admin_id, ban_reason, ban_date, unban_date)
  VALUES
  -- Bans by maximilian.mueller@example.com
  ((SELECT user_id FROM User WHERE email = 'tobias.keller@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'maximilian.mueller@example.com' AND a.admin_role = 'writer'),
   'Repeated platform policy violations including fraudulent reviews', '2025-06-29 10:00:00', '2026-06-29 10:00:00'),

  ((SELECT user_id FROM User WHERE email = 'christina.simon@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'maximilian.mueller@example.com' AND a.admin_role = 'writer'),
   'Unauthorized payment methods and chargeback abuse', '2025-06-30 10:00:00', '2026-06-30 10:00:00'),

  ((SELECT user_id FROM User WHERE email = 'michael.fuchs@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'maximilian.mueller@example.com' AND a.admin_role = 'writer'),
   'Property damage and refusal to pay compensation', '2025-07-01 10:00:00', '2026-07-01 10:00:00'),

  ((SELECT user_id FROM User WHERE email = 'katharina.herrmann@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'maximilian.mueller@example.com' AND a.admin_role = 'writer'),
   'Harassment of property owners', '2025-07-02 10:00:00', '2026-07-02 10:00:00'),

  ((SELECT user_id FROM User WHERE email = 'florian.lange@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'maximilian.mueller@example.com' AND a.admin_role = 'writer'),
   'Creating multiple accounts to circumvent restrictions', '2025-07-03 10:00:00', '2026-07-03 10:00:00'),

  -- Bans by sophie.schmidt@example.com
  ((SELECT user_id FROM User WHERE email = 'vanessa.busch@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'sophie.schmidt@example.com' AND a.admin_role = 'writer'),
   'Fake booking attempts and credit card testing', '2025-07-04 11:30:00', '2026-07-04 11:30:00'),

  ((SELECT user_id FROM User WHERE email = 'daniel.kuhn@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'sophie.schmidt@example.com' AND a.admin_role = 'writer'),
   'Repeated late cancellations causing host losses', '2025-07-05 11:30:00', '2026-07-05 11:30:00'),

  ((SELECT user_id FROM User WHERE email = 'kristin.jansen@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'sophie.schmidt@example.com' AND a.admin_role = 'writer'),
   'Misrepresentation of identity and booking purposes', '2025-07-06 11:30:00', '2026-07-06 11:30:00'),

  ((SELECT user_id FROM User WHERE email = 'philipp.winter@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'sophie.schmidt@example.com' AND a.admin_role = 'writer'),
   'Commercial use of personal account without authorization', '2025-07-07 11:30:00', '2026-07-07 11:30:00'),

  ((SELECT user_id FROM User WHERE email = 'jana.schulte@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'sophie.schmidt@example.com' AND a.admin_role = 'writer'),
   'Repeated violations of smoking policies in non-smoking properties', '2025-07-08 11:30:00', '2026-07-08 11:30:00'),

  -- Bans by alexander.schneider@example.com
  ((SELECT user_id FROM User WHERE email = 'matthias.koenig@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'alexander.schneider@example.com' AND a.admin_role = 'writer'),
   'Unauthorized subletting of booked accommodations', '2025-07-09 14:15:00', '2026-07-09 14:15:00'),

  ((SELECT user_id FROM User WHERE email = 'susanne.albrecht@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'alexander.schneider@example.com' AND a.admin_role = 'writer'),
   'Fraudulent damage claims against hosts', '2025-07-10 14:15:00', '2026-07-10 14:15:00'),

  ((SELECT user_id FROM User WHERE email = 'markus.graf@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'alexander.schneider@example.com' AND a.admin_role = 'writer'),
   'Excessive noise complaints from multiple properties', '2025-07-11 14:15:00', '2026-07-11 14:15:00'),

  ((SELECT user_id FROM User WHERE email = 'nadine.wild@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'alexander.schneider@example.com' AND a.admin_role = 'writer'),
   'False reporting of other users', '2025-07-12 14:15:00', '2026-07-12 14:15:00'),

  ((SELECT user_id FROM User WHERE email = 'stefan.brand@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'alexander.schneider@example.com' AND a.admin_role = 'writer'),
   'Attempting to circumvent payment systems', '2025-07-13 14:15:00', '2026-07-13 14:15:00'),

  -- Bans from different admins
  ((SELECT user_id FROM User WHERE email = 'patricia.reich@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'marie.fischer@example.com' AND a.admin_role = 'writer'),
   'Repeated last-minute cancellations with suspicious patterns', '2025-07-14 09:45:00', '2026-07-14 09:45:00'),

  ((SELECT user_id FROM User WHERE email = 'simon.arnold@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'paul.weber@example.com' AND a.admin_role = 'writer'),
   'Verbal abuse of property owners', '2025-07-15 16:20:00', '2026-07-15 16:20:00'),

  ((SELECT user_id FROM User WHERE email = 'christine.vogt@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'emilia.meyer@example.com' AND a.admin_role = 'writer'),
   'Unauthorized parties in booked accommodations', '2025-07-16 13:10:00', '2026-07-16 13:10:00'),

  ((SELECT user_id FROM User WHERE email = 'andreas.ott@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'marie.fischer@example.com' AND a.admin_role = 'writer'),
   'Repeated violations of pet policies', '2025-07-17 09:45:00', '2026-07-17 09:45:00'),

  ((SELECT user_id FROM User WHERE email = 'julia.krueger@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON a.admin_id = u.user_id WHERE u.email = 'paul.weber@example.com' AND a.admin_role = 'writer'),
   'Fake identity documents provided during verification', '2025-07-18 16:20:00', '2026-07-18 16:20:00')
;

-- Insert PropertyType Data with descriptions
INSERT INTO PropertyType (property_type_name, property_type_description) 
  VALUES
   ('Apartment', 'A self-contained housing unit occupying part of a building'),
   ('House', 'A standalone residential building'),
   ('Penthouse', 'An apartment on the top floor of a building, often luxurious'),
   ('Commercial', 'Property used for business or commercial purposes'),
   ('Cottage', 'A small, cozy house, typically in a rural or semi-rural location'),
   ('Studio', 'A small apartment combining living, sleeping, and cooking areas'),
   ('Industrial', 'Property used for manufacturing, production or storage'),
   ('Villa', 'A large, luxurious country house'),
   ('Flat', 'A self-contained housing unit within a larger building (UK term for apartment)'),
   ('Loft', 'An open, adaptable space often converted from industrial use'),
   ('Townhouse', 'A multi-floor home sharing walls with adjacent properties'),
   ('Retail', 'Property designed for selling goods directly to consumers'),
   ('Barn', 'A large farm building for storage or housing livestock'),
   ('Cabin', 'A small, rustic dwelling typically made of wood'),
   ('Mansion', 'A very large, impressive house'),
   ('Chalet', 'A wooden house with a sloping roof, common in mountain areas'),
   ('Bungalow', 'A small house or cottage typically having a single story'),
   ('Duplex', 'A building divided into two separate living units'),
   ('Farmhouse', 'The main house on a farm, often with surrounding land'),
   ('Others', 'Other types of properties not specifically categorized')
;

-- Insert Property Data
INSERT INTO Property (property_type_id, title, country, region, zip_code, property_address, square_feet)
VALUES
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Apartment'),
   'Modern Apartment in Berlin Mitte', 'Germany', 'Berlin', '10115', 'Invalidenstrasse 43, Berlin', 850),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'House'),
   'Charming House near Munich', 'Germany', 'Bavaria', '80331', 'Sendlinger Strasse 25, Muenchen', 2200),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Penthouse'),
   'Luxury Penthouse in Hamburg', 'Germany', 'Hamburg', '20095', 'Spitalerstrasse 10, Hamburg', 1500),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Commercial'),
   'Office Space in Frankfurt am Main', 'Germany', 'Hesse', '60311', 'Zeil 90, Frankfurt am Main', 3000),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Cottage'),
   'Rustic Cottage in Black Forest', 'Germany', 'Baden-Wuerttemberg', '79822', 'Feldbergstrasse 2, Schwarzwald', 1200),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Studio'),
   'Student Studio in Leipzig', 'Germany', 'Saxony', '04109', 'Karl-Liebknecht-Strasse 50, Leipzig', 400),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Industrial'),
   'Warehouse near Düsseldorf', 'Germany', 'North Rhine-Westphalia', '40210', 'Graf-Adolf-Strasse 12, Duesseldorf', 5000),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Villa'),
   'Historic Villa in Dresden', 'Germany', 'Saxony', '01067', 'Koenigstrasse 8, Dresden', 3500),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'House'),
   'Countryside Home in Lower Saxony', 'Germany', 'Lower Saxony', '30159', 'Bahnhofstrasse 18, Hannover', 1800),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Flat'),
   'Modern Flat in Stuttgart Center', 'Germany', 'Baden-Wuerttemberg', '70173', 'Koenigstrasse 45, Stuttgart', 950),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Chalet'),
   'Alpine Chalet in Garmisch', 'Germany', 'Bavaria', '82467', 'Zugspitzstrasse 1, Garmisch-Partenkirchen', 1600),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Bungalow'),
   'Seaside Bungalow in Kiel', 'Germany', 'Schleswig-Holstein', '24103', 'Kaistrasse 16, Kiel', 1100),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Loft'),
   'Loft Apartment in Cologne', 'Germany', 'North Rhine-Westphalia', '50667', 'Ehrenstrasse 22, Koeln', 1000),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Townhouse'),
   'Townhouse in Mainz Old Town', 'Germany', 'Rhineland-Palatinate', '55116', 'Augustinerstrasse 10, Mainz', 1300),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Penthouse'),
   'Penthouse in Freiburg', 'Germany', 'Baden-Wuerttemberg', '79098', 'Greiffeneggring 12, Freiburg', 350),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Villa'),
   'Villa near Bremen', 'Germany', 'Bremen', '28195', 'Weserstrasse 5, Bremen', 1400),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Commercial'),
   'Skyscraper Office in Stuttgart', 'Germany', 'Baden-Wuerttemberg', '70174', 'Rotebuehlstrasse 60, Stuttgart', 8000),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Cabin'),
   'Lakeview Cabin in Bavaria', 'Germany', 'Bavaria', '83209', 'Seestrasse 18, Prien am Chiemsee', 900),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Flat'),
   'Art Deco Flat in Nuremberg', 'Germany', 'Bavaria', '90402', 'Koenigstrasse 1, Nuernberg', 850),
  
  ((SELECT property_type_id FROM PropertyType WHERE property_type_name = 'Mansion'),
   'Luxury Mansion in Wiesbaden', 'Germany', 'Hesse', '65183', 'Wilhelmstrasse 34, Wiesbaden', 6000);

-- Insert PropertyAccess Data
INSERT INTO PropertyAccess (host_id, property_id)
-- Define a temporary table of (email, address) mappings then join to User, Host, and Property to bulk-insert.
  WITH
  access_pairs (email, property_address) AS (
      -- Map each host's email to a property property_address they should manage
      SELECT 'max.mustermann@example.com', 'Invalidenstrasse 43, Berlin' UNION ALL
      SELECT 'max.mustermann@example.com', 'Sendlinger Strasse 25, Muenchen' UNION ALL 
      SELECT 'max.mustermann@example.com', 'Spitalerstrasse 10, Hamburg' UNION ALL 
      SELECT 'lena.schmitt@example.com', 'Spitalerstrasse 10, Hamburg' UNION ALL 
      SELECT 'lena.schmitt@example.com', 'Zeil 90, Frankfurt am Main' UNION ALL 
      SELECT 'lena.schmitt@example.com', 'Feldbergstrasse 2, Schwarzwald' UNION ALL 
      SELECT 'fabian.huber@example.com', 'Karl-Liebknecht-Strasse 50, Leipzig' UNION ALL 
      SELECT 'julia.wagner@example.com', 'Graf-Adolf-Strasse 12, Duesseldorf' UNION ALL 
      SELECT 'fabian.huber@example.com', 'Graf-Adolf-Strasse 12, Duesseldorf' UNION ALL 
      SELECT 'tom.becker@example.com', 'Graf-Adolf-Strasse 12, Duesseldorf' UNION ALL 
      SELECT 'fabian.huber@example.com', 'Bahnhofstrasse 18, Hannover' UNION ALL 
      SELECT 'fabian.huber@example.com', 'Koenigstrasse 45, Stuttgart' UNION ALL 
      SELECT 'benno.mueller@example.com', 'Zugspitzstrasse 1, Garmisch-Partenkirchen' UNION ALL 
      SELECT 'johannes.wolf@example.com', 'Zugspitzstrasse 1, Garmisch-Partenkirchen' UNION ALL 
      SELECT 'sophia.wagner@example.com', 'Kaistrasse 16, Kiel' UNION ALL 
      SELECT 'benno.mueller@example.com', 'Ehrenstrasse 22, Koeln' UNION ALL 
      SELECT 'benno.mueller@example.com', 'Augustinerstrasse 10, Mainz' UNION ALL 
      SELECT 'tom.becker@example.com', 'Augustinerstrasse 10, Mainz' UNION ALL 
      SELECT 'hannah.schmidt@example.com', 'Greiffeneggring 12, Freiburg' UNION ALL 
      SELECT 'hannah.schmidt@example.com', 'Weserstrasse 5, Bremen' UNION ALL 
      SELECT 'christian.fischer@example.com', 'Rotebuehlstrasse 60, Stuttgart' UNION ALL 
      SELECT 'christian.fischer@example.com', 'Seestrasse 18, Prien am Chiemsee' UNION ALL 
      SELECT 'christian.fischer@example.com', 'Koenigstrasse 1, Nuernberg' UNION ALL 
      SELECT 'christian.fischer@example.com', 'Wilhelmstrasse 34, Wiesbaden' UNION ALL 
      SELECT 'jannes.koch@example.com', 'Wilhelmstrasse 34, Wiesbaden'
    )
  SELECT
    h.host_id, --  Use host_id from User table
    p.property_id -- Use property_id from Property table
  FROM access_pairs ap
  JOIN User u ON u.email = ap.email AND u.user_type = 'host'
  JOIN Host h ON h.host_id = u.user_id
  JOIN Property p ON p.property_address = ap.property_address
;

-- Insert CancellationPolicy Data
-- Policies are categorized by flexibility level and special conditions
INSERT INTO CancellationPolicy (policy_name, policy_description) 
  VALUES
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
  ('Stay Interrupted', 'Pro-rated refund if stay is cut short due to verifiable issues (e.g., heating failure).')
;

-- Insert Accommodation Data
INSERT INTO Accommodation (property_id, cancellation_policy_id, accommodation_tier, max_guest_count, unit_description, price_per_night)
  VALUES
  -- Berlin properties (prime and regular options)
  ((SELECT property_id FROM Property WHERE property_address = 'Invalidenstrasse 43, Berlin'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Flexible - 1 Day'),  -- Prime gets flexible policy
   'prime', 4, 'Modern loft in Berlin-Mitte with balcony overlooking Invalidenpark', 120.00),
  ((SELECT property_id FROM Property WHERE property_address = 'Invalidenstrasse 43, Berlin'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Moderate - 5 Days'),  -- Regular gets moderate policy
   'regular', 2, 'Compact designer studio in historic Berlin building', 75.50),

  -- Munich properties (Bavarian-style accommodations)
  ((SELECT property_id FROM Property WHERE property_address = 'Sendlinger Strasse 25, Muenchen'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Strict - 7 Days'),  -- Prime with strict policy
   'prime', 6, 'Bavarian luxury apartment on Munichs premier shopping street', 210.00),
  ((SELECT property_id FROM Property WHERE property_address = 'Sendlinger Strasse 25, Muenchen'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Flexible - Same Day'),  -- Regular with flexible policy
   'regular', 3, 'Charming Altbau apartment in central Munich location', 95.00),

  -- Hamburg properties (urban style)
  ((SELECT property_id FROM Property WHERE property_address = 'Spitalerstrasse 10, Hamburg'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Moderate - 3 Days'),  -- Prime urban loft
   'prime', 5, 'Stylish urban loft steps from Hamburgs main shopping district', 180.00),
  ((SELECT property_id FROM Property WHERE property_address = 'Spitalerstrasse 10, Hamburg'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Flexible - 1 Day'),  -- Cozy regular option
   'regular', 2, 'Cozy nest in the heart of Hamburg with city views', 85.00),

  -- Frankfurt properties (business travel focus)
  ((SELECT property_id FROM Property WHERE property_address = 'Zeil 90, Frankfurt am Main'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Strict - 14 Days'),  -- Executive prime apartment
   'prime', 4, 'Executive apartment on Frankfurts famous Zeil shopping street', 150.00),
  ((SELECT property_id FROM Property WHERE property_address = 'Zeil 90, Frankfurt am Main'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Moderate - 5 Days'),  -- Business-friendly regular
   'regular', 3, 'Comfortable city apartment with Main River glimpses', 99.00),

  -- Schwarzwald properties (mountain/rural focus)
  ((SELECT property_id FROM Property WHERE property_address = 'Feldbergstrasse 2, Schwarzwald'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Flexible - Same Day'),  -- Premium chalet
   'prime', 8, 'Authentic Black Forest chalet with mountain views and sauna', 250.00),
  ((SELECT property_id FROM Property WHERE property_address = 'Feldbergstrasse 2, Schwarzwald'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Moderate - 3 Days'),  -- Rustic regular cabin
   'regular', 4, 'Rustic cabin near Feldberg ski slopes', 110.00),

  -- Leipzig properties (historic city)
  ((SELECT property_id FROM Property WHERE property_address = 'Karl-Liebknecht-Strasse 50, Leipzig'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Flexible - 1 Day'),  -- Historic prime apartment
   'prime', 4, 'Historic apartment in Leipzigs trendy Südvorstadt district', 130.00),
  ((SELECT property_id FROM Property WHERE property_address = 'Karl-Liebknecht-Strasse 50, Leipzig'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Strict - 7 Days'),  -- Modern regular studio
   'regular', 2, 'Modern studio near Leipzig Hauptbahnhof', 65.00),

  -- Düsseldorf properties (luxury shopping focus)
  ((SELECT property_id FROM Property WHERE property_address = 'Graf-Adolf-Strasse 12, Duesseldorf'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Moderate - 5 Days'),  -- Elegant prime apartment
   'prime', 4, 'Elegant apartment steps from Königsallee shopping boulevard', 175.00),
  ((SELECT property_id FROM Property WHERE property_address = 'Graf-Adolf-Strasse 12, Duesseldorf'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Flexible - Same Day'),  -- Riverside regular
   'regular', 3, 'Bright riverside apartment in MedienHafen district', 105.00),
  
  -- Stuttgart properties (business/vineyard views)
  ((SELECT property_id FROM Property WHERE property_address = 'Rotebuehlstrasse 60, Stuttgart'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Strict - 14 Days'),  -- Luxury penthouse
   'prime', 5, 'Luxury penthouse with panoramic Stuttgart city views', 225.00),
  ((SELECT property_id FROM Property WHERE property_address = 'Rotebuehlstrasse 60, Stuttgart'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Moderate - 3 Days'),  -- Compact urban studio
   'regular', 2, 'Compact urban studio near Schlossplatz', 80.00),
  
  -- Garmisch-Partenkirchen (alpine properties)
  ((SELECT property_id FROM Property WHERE property_address = 'Zugspitzstrasse 1, Garmisch-Partenkirchen'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Flexible - 1 Day'),  -- Alpine lodge
   'prime', 6, 'Alpine lodge with direct Zugspitze mountain views', 195.00),
  ((SELECT property_id FROM Property WHERE property_address = 'Zugspitzstrasse 1, Garmisch-Partenkirchen'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Moderate - 5 Days'),  -- Bavarian guesthouse
   'regular', 4, 'Traditional Bavarian guesthouse with mountain access', 125.00),

   -- Cologne properties (cathedral views)
  ((SELECT property_id FROM Property WHERE property_address = 'Ehrenstrasse 22, Koeln'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Strict - 7 Days'),  -- Designer prime apartment
   'prime', 4, 'Designer apartment with Cologne Cathedral views', 160.00),
  ((SELECT property_id FROM Property WHERE property_address = 'Ehrenstrasse 22, Koeln'), 
   (SELECT policy_id FROM CancellationPolicy WHERE policy_name = 'Flexible - Same Day'),  -- Trendy regular flat
   'regular', 2, 'Charming flat in Colognes trendy Belgian Quarter', 90.00)
;

-- Insert AccommodationImage Data
INSERT INTO AccommodationImage (accommodation_id, image_url, image_description, display_order)
  VALUES
  -- Berlin images
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern loft in Berlin%'), 'https://example.com/images/berlin_loft_1.jpg', 'Spacious living area with balcony view', '1'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern loft in Berlin%'), 'https://example.com/images/berlin_loft_2.jpg', 'Modern kitchen with dining area', '2'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact designer studio in historic Ber%'), 'https://example.com/images/berlin_studio_1.jpg', 'Cozy studio with historic charm', '3'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact designer studio in historic Ber%'), 'https://example.com/images/berlin_studio_2.jpg', 'Designer furnishings and decor', '4'),

  -- Munich images
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bavarian luxury apartment%'), 'https://example.com/images/munich_apartment_1.jpg', 'Elegant living room with Bavarian decor', '1'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bavarian luxury apartment%'), 'https://example.com/images/munich_apartment_2.jpg', 'Spacious bedroom with city views', '2'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Charming Altbau apartment in central Mun%'), 'https://example.com/images/munich_altbau_1.jpg', 'Charming Altbau architecture', '3'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Charming Altbau apartment in central Mun%'), 'https://example.com/images/munich_altbau_2.jpg', 'Cozy living space with vintage touches', '4'),

  -- Hamburg images
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Stylish urban loft steps from Hamburg%'), 'https://example.com/images/hamburg_loft_1.jpg', 'Urban loft with modern furnishings', '1'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Stylish urban loft steps from Hamburg%'), 'https://example.com/images/hamburg_loft_2.jpg', 'View of the city skyline from the loft', '2'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Cozy nest in the heart of Hamburg%'), 'https://example.com/images/hamburg_nest_1.jpg', 'Cozy nest with city views', '3'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Cozy nest in the heart of Hamburg%'), 'https://example.com/images/hamburg_nest_2.jpg', 'Warm and inviting living area','4'),

  -- Frankfurt images
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Executive apartment on Frankfurts%'), 'https://example.com/images/frankfurt_executive_1.jpg', 'Executive living room with modern decor', '1'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Executive apartment on Frankfurts%'), 'https://example.com/images/frankfurt_executive_2.jpg', 'Stylish bedroom with city views', '2'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Comfortable city apartment with Main River%'), 'https://example.com/images/frankfurt_city_1.jpg', 'Comfortable living area with river view', '3'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Comfortable city apartment with Main River%'), 'https://example.com/images/frankfurt_city_2.jpg', 'Modern kitchen and dining space', '4'),

  -- Schwarzwald images
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Authentic Black Forest chalet%'), 'https://example.com/images/schwarzwald_chalet_1.jpg', 'Authentic chalet with mountain views', '1'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Authentic Black Forest chalet%'), 'https://example.com/images/schwarzwald_chalet_2.jpg', 'Cozy living area with fireplace', '2'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Rustic cabin near Feldberg ski slopes%'), 'https://example.com/images/schwarzwald_cabin_1.jpg', 'Rustic cabin with ski slope access','3'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Rustic cabin near Feldberg ski slopes%'), 'https://example.com/images/schwarzwald_cabin_2.jpg', 'Warm and inviting interior', '4'),

  -- Leipzig images
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Historic apartment in Leipzig%'), 'https://example.com/images/leipzig_historic_1.jpg', 'Historic apartment with vintage charm', '1'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Historic apartment in Leipzig%'), 'https://example.com/images/leipzig_historic_2.jpg', 'Spacious living area with period features', '2'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern studio near Leipzig Hauptbahnhof%'), 'https://example.com/images/leipzig_modern_1.jpg', 'Modern studio with contemporary design', '3'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern studio near Leipzig Hauptbahnhof%'), 'https://example.com/images/leipzig_modern_2.jpg', 'Compact and functional living space', '4'),

  -- Düsseldorf images
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Elegant apartment steps from Königsallee%'), 'https://example.com/images/duesseldorf_elegant_1.jpg', 'Elegant living room with luxury furnishings', '1'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Elegant apartment steps from Königsallee%'), 'https://example.com/images/duesseldorf_elegant_2.jpg', 'Stylish bedroom with shopping district views', '2'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bright riverside apartment in MedienHafen%'), 'https://example.com/images/duesseldorf_riverside_1.jpg', 'Bright riverside living area', '3'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bright riverside apartment in MedienHafen%'), 'https://example.com/images/duesseldorf_riverside_2.jpg', 'Modern kitchen with river views', '4'),

  -- Stuttgart images
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Luxury penthouse with panoramic Stuttgart%'), 'https://example.com/images/stuttgart_penthouse_1.jpg', 'Luxury penthouse with panoramic views', '1'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Luxury penthouse with panoramic Stuttgart%'), 'https://example.com/images/stuttgart_penthouse_2.jpg', 'Spacious terrace overlooking the city', '2'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact urban studio near Schlossplatz%'), 'https://example.com/images/stuttgart_studio_1.jpg', 'Compact studio with modern amenities', '3'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact urban studio near Schlossplatz%'), 'https://example.com/images/stuttgart_studio_2.jpg', 'Functional living space in the city center', '4'),

  -- Garmisch-Partenkirchen images
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Alpine lodge with direct Zugspitze%'), 'https://example.com/images/garmisch_lodge_1.jpg', 'Alpine lodge with Zugspitze views', '1'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Alpine lodge with direct Zugspitze%'), 'https://example.com/images/garmisch_lodge_2.jpg', 'Cozy interior with rustic charm', '2'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Traditional Bavarian guesthouse with mountain access%'), 'https://example.com/images/garmisch_guesthouse_1.jpg', 'Traditional Bavarian guesthouse exterior', '3'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Traditional Bavarian guesthouse with mountain access%'), 'https://example.com/images/garmisch_guesthouse_2.jpg', 'Warm and inviting guesthouse interior', '4'),

  -- Cologne images
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Designer apartment with Cologne Cathedral%'), 'https://example.com/images/cologne_designer_1.jpg', 'Designer apartment with cathedral views', '1'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Designer apartment with Cologne Cathedral%'), 'https://example.com/images/cologne_designer_2.jpg', 'Modern furnishings and decor', '2'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Charming flat in Colognes trendy Belgian Quarter%'), 'https://example.com/images/cologne_charming_1.jpg', 'Charming flat in Belgian Quarter with local art', '3'),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Charming flat in Colognes trendy Belgian Quarter%'), 'https://example.com/images/cologne_charming_2.jpg', 'Cozy living area with local art', '4')
;

-- Insert Amenity Data
-- Common amenities for properties and accommodations
INSERT INTO Amenity (amenity_name, amenity_description)
  VALUES
  -- Basic utilities
  ('WiFi', 'High-speed wireless internet access'),
  ('Air Conditioning', 'Climate control system'),
  ('Heating', 'Central heating system'),
  ('Washer', 'Washing machine available'),
  ('Dryer', 'Clothes dryer available'),
  ('Hot Water', 'Reliable hot water supply'),

  -- Kitchen amenities
  ('Refrigerator', 'Full-size refrigerator'),
  ('Microwave', 'Microwave oven'),
  ('Coffee Maker', 'Coffee brewing equipment'),
  ('Dishwasher', 'Built-in dishwasher'),

  -- Entertainment
  ('TV', 'Television with standard channels'),
  ('Cable TV', 'Premium cable television'),
  ('Streaming Services', 'Access to Netflix/Amazon Prime etc.'),

  -- Safety & Accessibility
  ('Smoke Alarm', 'Smoke detection system'),
  ('First Aid Kit', 'Basic medical supplies'),
  ('Fire Extinguisher', 'On-site fire safety equipment'),

  -- Outdoor & Luxury
  ('Pool', 'Swimming pool access'),
  ('Garden', 'Private outdoor garden area'),
  ('Parking', 'Dedicated parking space'),
  ('Gym', 'Exercise equipment available')
;

-- Insert AmenityAssignment Data
-- The amenity assignment is not realistic but is enough to showcase the functionality
INSERT INTO AmenityAssignment (accommodation_id, amenity_id)
  VALUES
  -- Berlin accommodations
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern loft in Berlin%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern loft in Berlin%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Air Conditioning')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern loft in Berlin%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Heating')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact designer studio in historic Ber%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact designer studio in historic Ber%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Microwave')),

  -- Munich accommodations
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bavarian luxury apartment%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bavarian luxury apartment%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Air Conditioning')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Charming Altbau apartment in central Mun%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Charming Altbau apartment in central Mun%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Heating')),

  -- Hamburg accommodations
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Stylish urban loft steps from Hamburg%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Stylish urban loft steps from Hamburg%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Air Conditioning')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Cozy nest in the heart of Hamburg%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Cozy nest in the heart of Hamburg%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Heating')),

  -- Frankfurt accommodations
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Executive apartment on Frankfurts%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Executive apartment on Frankfurts%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Air Conditioning')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Comfortable city apartment with Main River%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Comfortable city apartment with Main River%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Heating')),

  -- Schwarzwald accommodations
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Authentic Black Forest chalet%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Authentic Black Forest chalet%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Air Conditioning')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Rustic cabin near Feldberg ski slopes%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Rustic cabin near Feldberg ski slopes%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Heating')),

  -- Leipzig accommodations
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Historic apartment in Leipzig%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Historic apartment in Leipzig%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Air Conditioning')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern studio near Leipzig Hauptbahnhof%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern studio near Leipzig Hauptbahnhof%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Heating')),

  -- Düsseldorf accommodations
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Elegant apartment steps from Königsallee%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Elegant apartment steps from Königsallee%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Air Conditioning')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bright riverside apartment in MedienHafen%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bright riverside apartment in MedienHafen%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Heating')),

  -- Stuttgart accommodations
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Luxury penthouse with panoramic Stuttgart%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Luxury penthouse with panoramic Stuttgart%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Air Conditioning')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact urban studio near Schlossplatz%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact urban studio near Schlossplatz%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Heating')),

  -- Garmisch-Partenkirchen accommodations
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Alpine lodge with direct Zugspitze%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Alpine lodge with direct Zugspitze%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Air Conditioning')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Traditional Bavarian guesthouse with mountain access%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Traditional Bavarian guesthouse with mountain access%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Heating')),

  -- Cologne accommodations
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Designer apartment with Cologne Cathedral%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Designer apartment with Cologne Cathedral%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'Air Conditioning')),
  ((SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Charming flat in Colognes trendy Belgian Quarter%'), (SELECT amenity_id FROM Amenity WHERE amenity_name = 'WiFi'))
;

-- Insert Booking Data
INSERT INTO Booking (guest_id, accommodation_id, check_in_date, check_out_date, creation_date, booking_status)
  VALUES
  -- Premium guest booking prime accommodation in Berlin
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'sophie.koehler@example.com' AND g.membership_tier = 'premium'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern loft in Berlin%' AND accommodation_tier = 'prime'),
   '2023-07-01 15:00:00', '2023-07-05 11:00:00', '2023-06-01 09:00:00', 'confirmed'),

  -- Free guest booking regular accommodation in Berlin
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'charlotte.hofmann@example.com' AND g.membership_tier = 'free'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact designer studio in historic Ber%' AND accommodation_tier = 'regular'),
   '2023-12-15 16:00:00', '2023-12-20 10:00:00', '2023-11-01 10:00:00', 'pending'),

  -- Premium guest booking prime accommodation in Munich
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'emil.bergmann@example.com' AND g.membership_tier = 'premium'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bavarian luxury apartment%' AND accommodation_tier = 'prime'),
   '2023-07-10 14:00:00', '2023-07-15 10:00:00', '2023-05-20 11:30:00', 'confirmed'),

  -- Free guest booking regular accommodation in Munich
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'ben.hartmann@example.com' AND g.membership_tier = 'free'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Charming Altbau apartment in central Mun%' AND accommodation_tier = 'regular'),
   '2023-07-16 14:00:00', '2023-07-19 10:00:00', '2023-05-20 11:30:00', 'confirmed'),

  -- Premium guest booking prime accommodation in Hamburg
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'maja.pohl@example.com' AND g.membership_tier = 'premium'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Stylish urban loft steps from Hamburg%' AND accommodation_tier = 'prime'),
   '2023-08-05 13:00:00', '2023-08-12 11:00:00', '2023-07-01 14:00:00', 'confirmed'),

  -- Free guest booking regular accommodation in Hamburg
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'johanna.franke@example.com' AND g.membership_tier = 'free'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Cozy nest in the heart of Hamburg%' AND accommodation_tier = 'regular'),
   '2023-08-15 14:00:00', '2023-08-18 11:00:00', '2023-07-10 10:30:00', 'confirmed'),

  -- Premium guest booking prime accommodation in Frankfurt
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'leo.engel@example.com' AND g.membership_tier = 'premium'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Executive apartment on Frankfurts%' AND accommodation_tier = 'prime'),
   '2023-09-03 15:00:00', '2023-09-10 10:00:00', '2023-08-01 12:00:00', 'confirmed'),

  -- Free guest booking regular accommodation in Frankfurt
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'tim.walter@example.com' AND g.membership_tier = 'free'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Comfortable city apartment with Main River%' AND accommodation_tier = 'regular'),
   '2023-09-15 14:00:00', '2023-09-18 11:00:00', '2023-08-15 15:45:00', 'pending'),
  -- Premium guest booking prime accommodation in Schwarzwald
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'lena.mayer@example.com' AND g.membership_tier = 'premium'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Authentic Black Forest chalet%' AND accommodation_tier = 'prime'),
   '2023-10-01 16:00:00', '2023-10-08 10:00:00', '2023-09-01 09:30:00', 'confirmed'),

  -- Free guest booking regular accommodation in Schwarzwald
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'amelie.peters@example.com' AND g.membership_tier = 'free'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Rustic cabin near Feldberg ski slopes%' AND accommodation_tier = 'regular'),
   '2023-10-15 15:00:00', '2023-10-20 11:00:00', '2023-09-10 14:20:00', 'confirmed'),

  -- Premium guest booking prime accommodation in Leipzig
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'erik.winkler@example.com' AND g.membership_tier = 'premium'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Historic apartment in Leipzigs%' AND accommodation_tier = 'prime'),
   '2024-11-05 14:00:00', '2024-11-12 10:00:00', '2024-10-01 11:15:00', 'confirmed'),

  -- Free guest booking regular accommodation in Leipzig
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'moritz.kruse@example.com' AND g.membership_tier = 'free'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern studio near Leipzig Hauptbahnhof%' AND accommodation_tier = 'regular'),
   '2024-11-15 13:00:00', '2024-11-18 11:00:00', '2024-10-15 16:30:00', 'confirmed'),

  -- Premium guest booking prime accommodation in Düsseldorf
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'nele.gross@example.com' AND g.membership_tier = 'premium'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Elegant apartment steps from Königsallee%' AND accommodation_tier = 'prime'),
   '2024-12-01 15:00:00', '2024-12-08 10:00:00', '2024-11-01 10:45:00', 'confirmed'),

  -- Free guest booking regular accommodation in Düsseldorf
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'clara.brandt@example.com' AND g.membership_tier = 'free'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bright riverside apartment in MedienHafen%' AND accommodation_tier = 'regular'),
   '2024-12-10 14:00:00', '2024-12-15 11:00:00', '2024-11-10 14:10:00', 'pending'),

  -- Premium guest booking prime accommodation in Stuttgart
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'sophie.koehler@example.com' AND g.membership_tier = 'premium'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Luxury penthouse with panoramic Stuttgart%' AND accommodation_tier = 'prime'),
   '2024-01-05 16:00:00', '2024-01-12 10:00:00', '2023-12-01 09:20:00', 'confirmed'),

  -- Free guest booking regular accommodation in Stuttgart
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'noah.schuster@example.com' AND g.membership_tier = 'free'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact urban studio near Schlossplatz%' AND accommodation_tier = 'regular'),
   '2024-01-15 14:00:00', '2024-01-18 11:00:00', '2023-12-15 15:30:00', 'confirmed'),

  -- Premium guest booking prime accommodation in Garmisch-Partenkirchen
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'emil.bergmann@example.com' AND g.membership_tier = 'premium'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Alpine lodge with direct Zugspitze%' AND accommodation_tier = 'prime'),
   '2024-02-10 15:00:00', '2024-02-17 10:00:00', '2024-01-05 11:40:00', 'confirmed'),

  -- Free guest booking regular accommodation in Garmisch-Partenkirchen
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'luisa.vogel@example.com' AND g.membership_tier = 'free'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Traditional Bavarian guesthouse%' AND accommodation_tier = 'regular'),
   '2024-02-20 14:00:00', '2024-02-25 11:00:00', '2024-01-15 14:50:00', 'confirmed'),

  -- Premium guest booking prime accommodation in Cologne
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'maja.pohl@example.com' AND g.membership_tier = 'premium'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Designer apartment with Cologne Cathedral%' AND accommodation_tier = 'prime'),
   '2024-03-05 16:00:00', '2024-03-12 10:00:00', '2024-02-01 10:15:00', 'confirmed'),

  -- Free guest booking regular accommodation in Cologne
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'julian.seidel@example.com' AND g.membership_tier = 'free'),
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Charming flat in Cologne%' AND accommodation_tier = 'regular'),
   '2024-03-15 14:00:00', '2024-03-18 11:00:00', '2024-02-10 16:20:00', 'confirmed')
;

-- Insert Review Data
-- Reviews from guests about hosts and their accommodations
INSERT INTO Review (reviewer_id, reviewee_id, booking_id, rating, comment, review_date)
  VALUES
  -- Review for Berlin prime accommodation (rating 4)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'sophie.koehler@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'max.mustermann@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Modern loft in Berlin%'),
   4, 'Great stay in central Berlin, nice view, but unfortunately not perfectly clean.', '2023-07-06 11:00:00'),

  -- Review for Berlin regular accommodation (rating 5)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'charlotte.hofmann@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'max.mustermann@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Compact designer studio%'),
   5, 'Perfect little studio for our weekend getaway! Host was very responsive.', '2023-12-21 14:30:00'),

  -- Review for Munich prime accommodation (rating 5)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'emil.bergmann@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'lena.schmitt@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Bavarian luxury apartment%'),
   5, 'Absolutely stunning apartment in perfect location. Would definitely stay again!', '2023-07-16 09:15:00'),

  -- Review for Munich regular accommodation (rating 3)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'ben.hartmann@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'lena.schmitt@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Charming Altbau apartment%'),
   3, 'Good location but apartment was quite noisy at night.', '2023-07-20 16:45:00'),

  -- Review for Hamburg prime accommodation (rating 4)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'maja.pohl@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'fabian.huber@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Stylish urban loft%'),
   4, 'Fantastic views of the harbor! Minor issue with wifi connectivity.', '2023-08-13 10:20:00'),

  -- Review for Hamburg regular accommodation (rating 5)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'johanna.franke@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'fabian.huber@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Cozy nest in the heart%'),
   5, 'Cozy indeed! Perfect for our romantic weekend. Everything was spotless.', '2023-08-19 12:00:00'),

  -- Review for Frankfurt prime accommodation (rating 4)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'leo.engel@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'tom.becker@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Executive apartment%'),
   4, 'Excellent business stay. Great location for meetings on Zeil.', '2023-09-11 08:30:00'),

  -- Review for Frankfurt regular accommodation (rating 2)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'tim.walter@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'tom.becker@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Comfortable city apartment%'),
   2, 'Apartment was smaller than expected and quite warm with no AC.', '2023-09-19 15:10:00'),

  -- Review for Schwarzwald prime accommodation (rating 5)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'lena.mayer@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'benno.mueller@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Authentic Black Forest chalet%'),
   5, 'Magical winter getaway! The sauna was perfect after skiing.', '2023-10-09 11:45:00'),

  -- Review for Schwarzwald regular accommodation (rating 4)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'amelie.peters@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'benno.mueller@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Rustic cabin%'),
   4, 'Charming cabin with everything we needed. Great hiking nearby.', '2023-10-21 13:20:00'),

  -- Review for Leipzig prime accommodation (rating 5)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'erik.winkler@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'julia.wagner@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Historic apartment%'),
   5, 'Beautiful historic building with modern comforts. Host was very helpful!', '2023-11-13 09:30:00'),

  -- Review for Leipzig regular accommodation (rating 3)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'moritz.kruse@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'julia.wagner@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Modern studio%'),
   3, 'Convenient location but quite noisy from street traffic.', '2023-11-19 14:15:00'),

  -- Review for Düsseldorf prime accommodation (rating 4)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'nele.gross@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'fabian.huber@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Elegant apartment steps%'),
   4, 'Luxurious apartment in perfect shopping location. Would stay again!', '2023-12-09 10:50:00'),

  -- Review for Düsseldorf regular accommodation (rating 4)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'clara.brandt@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'fabian.huber@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Bright riverside apartment%'),
   4, 'Lovely views of the river. Apartment was clean and well-equipped.', '2023-12-16 12:30:00'),

  -- Review for Stuttgart prime accommodation (rating 5)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'sophie.koehler@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'christian.fischer@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Luxury penthouse%'),
   5, 'Spectacular views of Stuttgart! Everything was perfect.', '2024-01-13 09:00:00'),

  -- Review for Stuttgart regular accommodation (rating 3)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'noah.schuster@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'christian.fischer@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Compact urban studio%'),
   3, 'Small but functional. Good value for money in central location.', '2024-01-19 15:45:00'),

  -- Review for Garmisch-Partenkirchen prime accommodation (rating 5)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'emil.bergmann@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'johannes.wolf@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Alpine lodge%'),
   5, 'Breathtaking mountain views! The perfect ski vacation home.', '2024-02-18 11:20:00'),

  -- Review for Garmisch-Partenkirchen regular accommodation (rating 4)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'luisa.vogel@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'johannes.wolf@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Traditional Bavarian guesthouse%'),
   4, 'Authentic Bavarian experience. Very cozy and warm in winter.', '2024-02-26 13:10:00'),

  -- Review for Cologne prime accommodation (rating 5)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'maja.pohl@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'hannah.schmidt@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Designer apartment%'),
   5, 'Waking up to cathedral views was unforgettable! Perfect location.', '2024-03-13 10:00:00'),

  -- Review for Cologne regular accommodation (rating 4)
  ((SELECT g.guest_id FROM User u JOIN Guest g ON u.user_id = g.guest_id WHERE u.email = 'julian.seidel@example.com'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'hannah.schmidt@example.com'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Charming flat%'),
   4, 'Great neighborhood with cool bars and restaurants. Flat was comfortable.', '2024-03-19 14:30:00')
;

-- Insert UserMessage Data
-- Notification messages sent by reader-role admins to banned users
-- All messages sent on the user's ban date with appropriate content
INSERT INTO UserMessage (sender_id, recipient_id, content, sent_date)
VALUES
-- First 5 messages from leon.wagner@example.com
((SELECT user_id FROM User WHERE email = 'leon.wagner@example.com'),
 (SELECT user_id FROM User WHERE email = 'tobias.keller@example.com'),
'Dear Tobias Keller, we are hereby notifying you that your account has been suspended due to repeated platform policy violations. Duration: 1 year.', 
'2025-06-28 10:05:00'),

((SELECT user_id FROM User WHERE email = 'leon.wagner@example.com'),
 (SELECT user_id FROM User WHERE email = 'christina.simon@example.com'),
'Dear Christina Simon, your account has been suspended for unauthorized payment methods and chargeback abuse. Duration: 1 year.', 
'2025-06-29 10:05:00'),

((SELECT user_id FROM User WHERE email = 'leon.wagner@example.com'),
 (SELECT user_id FROM User WHERE email = 'michael.fuchs@example.com'),
'Dear Michael Fuchs, we have suspended your account due to property damage and refusal to pay compensation. Duration: 1 year.', 
'2025-06-30 10:05:00'),

((SELECT user_id FROM User WHERE email = 'leon.wagner@example.com'),
 (SELECT user_id FROM User WHERE email = 'katharina.herrmann@example.com'),
'Dear Katharina Herrmann, your account has been suspended for harassment of property owners. Duration: 1 year.', 
'2025-07-01 10:05:00'),

((SELECT user_id FROM User WHERE email = 'leon.wagner@example.com'),
 (SELECT user_id FROM User WHERE email = 'florian.lange@example.com'),
'Dear Florian Lange, we have suspended your account for creating multiple accounts to circumvent restrictions. Duration: 1 year.', 
'2025-07-02 10:05:00'),

-- Next 5 messages from anna.becker@example.com
((SELECT user_id FROM User WHERE email = 'anna.becker@example.com'),
 (SELECT user_id FROM User WHERE email = 'vanessa.busch@example.com'),
'Dear Vanessa Busch, your account has been suspended for fake booking attempts and credit card testing. Duration: 1 year.', 
'2025-07-03 11:35:00'),

((SELECT user_id FROM User WHERE email = 'anna.becker@example.com'),
 (SELECT user_id FROM User WHERE email = 'daniel.kuhn@example.com'),
'Dear Daniel Kuhn, we have suspended your account due to repeated late cancellations causing host losses. Duration: 1 year.', 
'2025-07-04 11:35:00'),

((SELECT user_id FROM User WHERE email = 'anna.becker@example.com'),
 (SELECT user_id FROM User WHERE email = 'kristin.jansen@example.com'),
'Dear Kristin Jansen, your account has been suspended for misrepresentation of identity and booking purposes. Duration: 1 year.', 
'2025-07-05 11:35:00'),

((SELECT user_id FROM User WHERE email = 'anna.becker@example.com'),
 (SELECT user_id FROM User WHERE email = 'philipp.winter@example.com'),
'Dear Philipp Winter, we have suspended your account for commercial use of personal account without authorization. Duration: 1 year.', 
'2025-07-06 11:35:00'),

((SELECT user_id FROM User WHERE email = 'anna.becker@example.com'),
 (SELECT user_id FROM User WHERE email = 'jana.schulte@example.com'),
'Dear Jana Schulte, your account has been suspended for repeated violations of smoking policies. Duration: 1 year.', 
'2025-07-07 11:35:00'),

-- Next 5 messages from felix.schulz@example.com
((SELECT user_id FROM User WHERE email = 'felix.schulz@example.com'),
 (SELECT user_id FROM User WHERE email = 'matthias.koenig@example.com'),
'Dear Matthias König, we have suspended your account for unauthorized subletting of booked accommodations. Duration: 1 year.', 
'2025-07-08 14:20:00'),

((SELECT user_id FROM User WHERE email = 'felix.schulz@example.com'),
 (SELECT user_id FROM User WHERE email = 'susanne.albrecht@example.com'),
'Dear Susanne Albrecht, your account has been suspended for fraudulent damage claims against hosts. Duration: 1 year.', 
'2025-07-09 14:20:00'),

((SELECT user_id FROM User WHERE email = 'felix.schulz@example.com'),
 (SELECT user_id FROM User WHERE email = 'markus.graf@example.com'),
'Dear Markus Graf, we have suspended your account due to excessive noise complaints from multiple properties. Duration: 1 year.', 
'2025-07-10 14:20:00'),

((SELECT user_id FROM User WHERE email = 'felix.schulz@example.com'),
 (SELECT user_id FROM User WHERE email = 'nadine.wild@example.com'),
'Dear Nadine Wild, your account has been suspended for false reporting of other users. Duration: 1 year.', 
'2025-07-11 14:20:00'),

((SELECT user_id FROM User WHERE email = 'felix.schulz@example.com'),
 (SELECT user_id FROM User WHERE email = 'stefan.brand@example.com'),
'Dear Stefan Brand, we have suspended your account for attempting to circumvent payment systems. Duration: 1 year.', 
'2025-07-12 14:20:00'),

-- Final 5 messages distributed among remaining reader admins
((SELECT user_id FROM User WHERE email = 'mia.hoffmann@example.com'),
 (SELECT user_id FROM User WHERE email = 'patricia.reich@example.com'),
'Dear Patricia Reich, your account has been suspended for repeated last-minute cancellations with suspicious patterns. Duration: 1 year.', 
'2025-07-13 09:50:00'),

((SELECT user_id FROM User WHERE email = 'lukas.schaefer@example.com'),
 (SELECT user_id FROM User WHERE email = 'simon.arnold@example.com'),
'Dear Simon Arnold, we have suspended your account for verbal abuse of property owners. Duration: 1 year.', 
'2025-07-14 16:25:00'),

((SELECT user_id FROM User WHERE email = 'lena.koch@example.com'),
 (SELECT user_id FROM User WHERE email = 'christine.vogt@example.com'),
'Dear Christine Vogt, your account has been suspended for unauthorized parties in booked accommodations. Duration: 1 year.', 
'2025-07-15 13:15:00'),

((SELECT user_id FROM User WHERE email = 'elias.bauer@example.com'),
 (SELECT user_id FROM User WHERE email = 'andreas.ott@example.com'),
'Dear Andreas Ott, we have suspended your account for repeated violations of pet policies. Duration: 1 year.', 
'2025-07-16 09:50:00'),

((SELECT user_id FROM User WHERE email = 'laura.richter@example.com'),
 (SELECT user_id FROM User WHERE email = 'julia.krueger@example.com'),
'Dear Julia Krüger, your account has been suspended for providing fake identity documents during verification. Duration: 1 year.', 
'2025-07-17 16:25:00');

-- Insert Wishlist Data
INSERT INTO Wishlist (guest_id, wishlist_title)
VALUES
  ((SELECT user_id FROM User WHERE email = 'niklas.meier@example.com' AND user_type = 'guest'), 'Summer vacation'),
  ((SELECT user_id FROM User WHERE email = 'charlotte.hofmann@example.com' AND user_type = 'guest'), 'Future Travel Plans'),
  ((SELECT user_id FROM User WHERE email = 'ben.hartmann@example.com' AND user_type = 'guest'), 'Cozy Winter Getaways'),
  ((SELECT user_id FROM User WHERE email = 'johanna.franke@example.com' AND user_type = 'guest'), 'Summer Escapes'),
  ((SELECT user_id FROM User WHERE email = 'tim.walter@example.com' AND user_type = 'guest'), 'City Breaks and Culture Trips'),
  ((SELECT user_id FROM User WHERE email = 'amelie.peters@example.com' AND user_type = 'guest'), 'Romantic Getaways'),
  ((SELECT user_id FROM User WHERE email = 'moritz.kruse@example.com' AND user_type = 'guest'), 'Adventure Travel'),
  ((SELECT user_id FROM User WHERE email = 'clara.brandt@example.com' AND user_type = 'guest'), 'Luxury Resorts'),
  ((SELECT user_id FROM User WHERE email = 'noah.schuster@example.com' AND user_type = 'guest'), 'Road Trip Ideas'),
  ((SELECT user_id FROM User WHERE email = 'luisa.vogel@example.com' AND user_type = 'guest'), 'Mountain Retreats'),
  ((SELECT user_id FROM User WHERE email = 'julian.seidel@example.com' AND user_type = 'guest'), 'Foodie Destinations'),
  ((SELECT user_id FROM User WHERE email = 'marieke.hansen@example.com' AND user_type = 'guest'), 'Spa and Wellness'),
  ((SELECT user_id FROM User WHERE email = 'david.lehmann@example.com' AND user_type = 'guest'), 'Historical Sites'),
  ((SELECT user_id FROM User WHERE email = 'sophie.koehler@example.com' AND user_type = 'guest'), 'Island Hopping'),
  ((SELECT user_id FROM User WHERE email = 'emil.bergmann@example.com' AND user_type = 'guest'), 'Ski Resorts'),
  ((SELECT user_id FROM User WHERE email = 'maja.pohl@example.com' AND user_type = 'guest'), 'Family Vacation Spots'),
  ((SELECT user_id FROM User WHERE email = 'leo.engel@example.com' AND user_type = 'guest'), 'Backpacking Adventures'),
  ((SELECT user_id FROM User WHERE email = 'lena.mayer@example.com' AND user_type = 'guest'), 'Wine Country Tours'),
  ((SELECT user_id FROM User WHERE email = 'erik.winkler@example.com' AND user_type = 'guest'), 'National Parks'),
  ((SELECT user_id FROM User WHERE email = 'nele.gross@example.com' AND user_type = 'guest'), 'Bucket List Destinations')
;

-- Insert WishlistItem Data
INSERT INTO WishlistItem (wishlist_id, accommodation_id)
VALUES
  -- Summer vacation 
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Summer vacation'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern loft in Berlin%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Summer vacation'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Cozy nest in the heart%')),

  -- Future Travel Plans
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Future Travel Plans'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bavarian luxury apartment%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Future Travel Plans'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Authentic Black Forest chalet%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Future Travel Plans'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Alpine lodge%')),

  -- Cozy Winter Getaways 
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Cozy Winter Getaways'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Rustic cabin%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Cozy Winter Getaways'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Traditional Bavarian guesthouse%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Cozy Winter Getaways'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Authentic Black Forest chalet%')),

  -- Summer Beach Escapes 
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Summer Escapes'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Modern loft in Berlin%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Summer Escapes'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Stylish urban loft%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Summer Escapes'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Designer apartment%')),

  -- City Breaks and Culture Trips
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'City Breaks and Culture Trips'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Historic apartment%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'City Breaks and Culture Trips'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Compact designer studio%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'City Breaks and Culture Trips'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Elegant apartment steps%')),

  -- Romantic Getaways
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Romantic Getaways'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Bavarian luxury apartment%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Romantic Getaways'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Luxury penthouse%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Romantic Getaways'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Designer apartment%')),

  -- Adventure Travel
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Adventure Travel'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Alpine lodge%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Adventure Travel'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Rustic cabin%')),
  ((SELECT wishlist_id FROM Wishlist WHERE wishlist_title = 'Adventure Travel'), 
   (SELECT accommodation_id FROM Accommodation WHERE unit_description LIKE '%Authentic Black Forest chalet%'))
;

-- Insert PaymentMethod Data
INSERT INTO PaymentMethod (payment_name)
VALUES
   ('Bank Transfer'),
   ('PayPal'),
   ('Credit Card'),
   ('Debit Card'),
   ('Wire Transfer'),
   ('SEPA Transfer'),
   ('ACH Transfer'),
   ('Apple Pay'),
   ('Google Pay'),
   ('Venmo'),
   ('Cash App'),
   ('Wise'),
   ('Revolut'),
   ('Skrill'),
   ('Neteller'),
   ('Payoneer'),
   ('Stripe'),
   ('Cryptocurrency'),
   ('Alipay'),
   ('WeChat Pay');

-- Insert Payout Data
INSERT INTO Payout (payment_method_id, host_id, amount, payout_date)
VALUES
  -- Max Mustermann
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'max.mustermann@example.com'),
   1500.00, '2023-07-10 12:00:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'max.mustermann@example.com'),
   1800.50, '2023-08-15 09:30:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'max.mustermann@example.com'),
   1650.75, '2023-09-12 14:15:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'max.mustermann@example.com'),
   1920.25, '2023-10-18 11:45:00'),
  
  -- Lena Schmitt 
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'PayPal'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'lena.schmitt@example.com'),
   2200.75, '2023-07-12 14:15:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'PayPal'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'lena.schmitt@example.com'),
   1950.25, '2023-08-18 11:45:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'lena.schmitt@example.com'),
   2400.50, '2023-09-20 16:30:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'lena.schmitt@example.com'),
   2100.00, '2023-10-25 10:20:00'),

  -- Fabian Huber 
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'fabian.huber@example.com'),
   3200.00, '2023-07-15 16:20:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'fabian.huber@example.com'),
   2750.80, '2023-08-20 13:10:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Cryptocurrency'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'fabian.huber@example.com'),
   2300.00, '2023-11-15 16:20:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Cryptocurrency'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'fabian.huber@example.com'),
   1850.80, '2023-10-20 13:10:00'),

  -- Julia Wagner
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'julia.wagner@example.com'),
   1450.60, '2023-07-18 10:45:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'julia.wagner@example.com'),
   1600.40, '2023-08-22 15:30:00'),

  -- Tom Becker
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'tom.becker@example.com'),
   2300.25, '2023-07-20 11:20:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'tom.becker@example.com'),
   2100.75, '2023-08-25 14:50:00'),

  -- Lea Maier
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'lea.maier@example.com'),
   1750.90, '2023-07-22 09:15:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'lea.maier@example.com'),
   1850.10, '2023-08-28 16:25:00'),

  -- Benno Mueller
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Cryptocurrency'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'benno.mueller@example.com'),
   2800.50, '2023-07-25 13:40:00'),
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Cryptocurrency'),
   (SELECT h.host_id FROM User u JOIN Host h ON u.user_id = h.host_id WHERE u.email = 'benno.mueller@example.com'),
   2950.00, '2023-08-30 10:15:00');

-- Insert Payment Data
INSERT INTO Payment (payment_method_id, referral_id, booking_id, amount, payment_date, payment_status)
VALUES
  -- Credit Card payments
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'), 
   (SELECT referral_id FROM UserReferral WHERE referral_code = '684932'), 
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Modern loft in Berlin%'),
   200.00, '2023-07-01 10:00:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   (SELECT referral_id FROM UserReferral WHERE referral_code = '217845'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Bavarian luxury apartment%'),
   200.00, '2023-07-10 09:15:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Charming Altbau apartment%'),
   320.00, '2023-07-18 16:45:00', 'failed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   (SELECT referral_id FROM UserReferral WHERE referral_code = '892345'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Cozy nest in the heart%'),
   200.00, '2023-08-15 12:00:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Comfortable city apartment%'),
   280.00, '2023-09-15 15:10:00', 'pending'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   (SELECT referral_id FROM UserReferral WHERE referral_code = '901234'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Authentic Black Forest chalet%'),
   200.00, '2023-10-05 11:45:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Credit Card'),
   (SELECT referral_id FROM UserReferral WHERE referral_code = '567890'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Historic apartment%'),
   200.00, '2023-11-10 09:30:00', 'completed'),

  -- PayPal payments
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'PayPal'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Compact designer studio%'),
   450.00, '2023-12-15 14:30:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'PayPal'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Executive apartment%'),
   620.00, '2023-09-05 08:30:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'PayPal'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Modern studio%'),
   420.00, '2023-11-15 14:15:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'PayPal'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Compact urban studio%'),
   290.00, '2024-01-15 15:45:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'PayPal'),
   (SELECT referral_id FROM UserReferral WHERE referral_code = '123456'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Elegant apartment steps%'),
   200.00, '2023-12-05 10:50:00', 'completed'),

  -- Bank Transfer payments
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Stylish urban loft%'),
   580.00, '2023-08-10 10:20:00', 'refunded'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Rustic cabin%'),
   380.00, '2023-10-18 13:20:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Bright riverside apartment%'),
   510.00, '2023-12-12 12:30:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   (SELECT referral_id FROM UserReferral WHERE referral_code = '345012'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Luxury penthouse%'),
   200.00, '2024-01-10 09:00:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Bank Transfer'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Traditional Bavarian guesthouse%'),
   340.00, '2024-02-22 13:10:00', 'completed'),

  -- Cryptocurrency payments
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Cryptocurrency'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Designer apartment%'),
   720.00, '2024-03-10 10:00:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Cryptocurrency'),
   (SELECT referral_id FROM UserReferral WHERE referral_code = '789456'),
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Alpine lodge%'),
   200.00, '2024-02-15 11:20:00', 'completed'),
  
  ((SELECT payment_method_id FROM PaymentMethod WHERE payment_name = 'Cryptocurrency'),
   NULL,
   (SELECT b.booking_id FROM Booking b JOIN Accommodation a ON b.accommodation_id = a.accommodation_id WHERE a.unit_description LIKE '%Charming flat%'),
   390.00, '2024-03-15 14:30:00', 'pending');
-- Insert SupportTicket Data
INSERT INTO SupportTicket (user_id, assigned_admin_id, ticket_subject, ticket_description, ticket_status, creation_date, update_date)
VALUES
  -- Tobias Keller (open ticket assigned to reader)
  ((SELECT user_id FROM User WHERE email = 'tobias.keller@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'leon.wagner@example.com'),
   'Account Suspension Appeal', 'I would like to appeal my account suspension. I believe it was a misunderstanding regarding my payment method. Please review my case.',
   'open', '2025-06-28 10:05:00', '2025-06-28 10:05:00'),
  
  -- Christina Simon (closed by writer)
  ((SELECT user_id FROM User WHERE email = 'christina.simon@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'maximilian.mueller@example.com'),
   'Unauthorized Payment Method', 'My account was suspended for using an unauthorized payment method. I would like to clarify that I was not aware of this policy.',
   'closed', '2025-06-29 10:05:00', '2025-06-29 14:30:00'),
  
  -- Michael Fuchs (in progress with writer)
  ((SELECT user_id FROM User WHERE email = 'michael.fuchs@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'sophie.schmidt@example.com'),
   'Booking Refund Request', 'I cancelled my booking within the allowed period but have not received my refund. It is been over 14 business days.',
   'in_progress', '2025-06-30 11:20:00', '2025-07-01 09:15:00'),
  
  -- Katharina Herrmann (resolved by writer)
  ((SELECT user_id FROM User WHERE email = 'katharina.herrmann@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'alexander.schneider@example.com'),
   'Host Verification Issue', 'I have submitted all documents for host verification but my status has not been updated for 2 weeks.',
   'resolved', '2025-07-01 14:45:00', '2025-07-03 16:20:00'),
  
  -- Florian Lange (open ticket unassigned)
  ((SELECT user_id FROM User WHERE email = 'florian.lange@example.com'),
   NULL,
   'Security Concern', 'I received a suspicious message from another user asking for personal information. Is this normal?',
   'open', '2025-07-02 09:30:00', '2025-07-02 09:30:00'),
  
  -- Vanessa Busch (closed by writer)
  ((SELECT user_id FROM User WHERE email = 'vanessa.busch@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'marie.fischer@example.com'),
   'Payment Dispute', 'I was charged twice for the same booking. Please refund the duplicate charge.',
   'closed', '2025-07-03 16:10:00', '2025-07-05 11:45:00'),
  
  -- Daniel Kuhn (in progress with writer)
  ((SELECT user_id FROM User WHERE email = 'daniel.kuhn@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'paul.weber@example.com'),
   'Account Access Problem', 'I can not log in to my account even after resetting my password multiple times.',
   'in_progress', '2025-07-04 13:25:00', '2025-07-05 10:30:00'),
  
  -- Kristin Jansen (resolved by writer)
  ((SELECT user_id FROM User WHERE email = 'kristin.jansen@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'emilia.meyer@example.com'),
   'Review Removal Request', 'I believe my recent review was unfairly removed. Can you explain why?',
   'resolved', '2025-07-05 10:15:00', '2025-07-07 14:00:00'),
  
  -- Philipp Winter (open ticket assigned to reader)
  ((SELECT user_id FROM User WHERE email = 'philipp.winter@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'anna.becker@example.com'),
   'Listing Accuracy Concern', 'The accommodation I booked did not match the description. What are my options?',
   'open', '2025-07-06 11:40:00', '2025-07-06 11:40:00'),
  
  -- Jana Schulte (closed by writer)
  ((SELECT user_id FROM User WHERE email = 'jana.schulte@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'maximilian.mueller@example.com'),
   'Host Communication Issue', 'The host is not responding to my messages about check-in instructions.',
   'closed', '2025-07-07 15:20:00', '2025-07-09 09:10:00'),
  
  -- Matthias Koenig (in progress with writer)
  ((SELECT user_id FROM User WHERE email = 'matthias.koenig@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'sophie.schmidt@example.com'),
   'Cancellation Policy Question', 'I need to cancel due to an emergency but I am past the free cancellation period.',
   'in_progress', '2025-07-08 09:45:00', '2025-07-08 16:30:00'),
  
  -- Susanne Albrecht (resolved by writer)
  ((SELECT user_id FROM User WHERE email = 'susanne.albrecht@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'alexander.schneider@example.com'),
   'Profile Verification Delay', 'My ID verification has been pending for over 10 days. When will this be completed?',
   'resolved', '2025-07-09 14:10:00', '2025-07-11 11:15:00'),
  
  -- Markus Graf (open ticket unassigned)
  ((SELECT user_id FROM User WHERE email = 'markus.graf@example.com'),
   NULL,
   'Safety Concern', 'I had a concerning experience with another user and want to report it.',
   'open', '2025-07-10 10:30:00', '2025-07-10 10:30:00'),
  
  -- Nadine Wild (closed by writer)
  ((SELECT user_id FROM User WHERE email = 'nadine.wild@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'marie.fischer@example.com'),
   'Refund Processing Time', 'How long does it typically take for refunds to appear in my bank account?',
   'closed', '2025-07-11 13:50:00', '2025-07-12 15:20:00'),
  
  -- Stefan Brand (in progress with writer)
  ((SELECT user_id FROM User WHERE email = 'stefan.brand@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'paul.weber@example.com'),
   'Listing Photos Problem', 'The photos in my listing are not uploading correctly. Some appear rotated or cropped.',
   'in_progress', '2025-07-12 16:05:00', '2025-07-13 10:45:00'),
  
  -- Patricia Reich (resolved by writer)
  ((SELECT user_id FROM User WHERE email = 'patricia.reich@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'emilia.meyer@example.com'),
   'Pricing Display Issue', 'The total price shown during booking did not match the final charge on my card.',
   'resolved', '2025-07-13 11:25:00', '2025-07-15 14:30:00'),
  
  -- Simon Arnold (open ticket assigned to reader)
  ((SELECT user_id FROM User WHERE email = 'simon.arnold@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'felix.schulz@example.com'),
   'Account Security Alert', 'I received a login attempt notification from an unknown device.',
   'open', '2025-07-14 09:15:00', '2025-07-14 09:15:00'),
  
  -- Christine Vogt (closed by writer)
  ((SELECT user_id FROM User WHERE email = 'christine.vogt@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'maximilian.mueller@example.com'),
   'Host Rating System', 'How does the host rating system work? I had a bad experience but do not see any negative reviews.',
   'closed', '2025-07-15 14:40:00', '2025-07-17 10:20:00'),
  
  -- Andreas Ott (in progress with writer)
  ((SELECT user_id FROM User WHERE email = 'andreas.ott@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'sophie.schmidt@example.com'),
   'Payment Method Change', 'I need to update my payment method but the system does not let me add a new card.',
   'in_progress', '2025-07-16 10:50:00', '2025-07-17 15:10:00'),
  
  -- Julia Krueger (resolved by writer)
  ((SELECT user_id FROM User WHERE email = 'julia.krueger@example.com'),
   (SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'alexander.schneider@example.com'),
   'Booking Modification Request', 'I need to change the dates of my booking but can not find the option to do so.',
   'resolved', '2025-07-17 13:30:00', '2025-07-19 11:45:00')
;

-- Insert AppNotification Data (20 entries)
INSERT INTO AppNotification (user_id, notification_type, notification_message, is_read, notification_date)
VALUES
  -- Niklas Meier
  ((SELECT user_id FROM User WHERE email = 'niklas.meier@example.com'),
   'system', 'Your account has been successfully verified. You can now book accommodations.',
   FALSE, '2025-03-01 10:00:00'),
  
  -- Charlotte Hofmann
  ((SELECT user_id FROM User WHERE email = 'charlotte.hofmann@example.com'),
   'booking', 'Your booking for "Modern loft in Berlin" has been confirmed for March 15-20, 2025.',
   TRUE, '2025-03-02 14:30:00'),
  
  -- Ben Hartmann
  ((SELECT user_id FROM User WHERE email = 'ben.hartmann@example.com'),
   'payment', 'Your payment of €450.00 for booking #32567 has been processed successfully.',
   TRUE, '2025-03-03 09:15:00'),
  
  -- Johanna Franke
  ((SELECT user_id FROM User WHERE email = 'johanna.franke@example.com'),
   'promotion', 'Special offer: 15% off all bookings in Munich this spring! Use code SPRING15.',
   FALSE, '2025-03-05 11:20:00'),
  
  -- Tim Walter
  ((SELECT user_id FROM User WHERE email = 'tim.walter@example.com'),
   'review', 'Please rate your recent stay at "Cozy nest in the heart of Hamburg".',
   FALSE, '2025-03-07 16:45:00'),
  
  -- Amelie Peters
  ((SELECT user_id FROM User WHERE email = 'amelie.peters@example.com'),
   'system', 'We have updated our privacy policy. Please review the changes.',
   TRUE, '2025-03-08 08:30:00'),
  
  -- Moritz Kruse
  ((SELECT user_id FROM User WHERE email = 'moritz.kruse@example.com'),
   'booking', 'Reminder: Your stay at "Stylish urban loft" starts in 3 days.',
   FALSE, '2025-03-10 12:10:00'),
  
  -- Clara Brandt
  ((SELECT user_id FROM User WHERE email = 'clara.brandt@example.com'),
   'payment', 'Your refund of €320.00 for booking #32568 has been processed.',
   TRUE, '2025-03-12 15:20:00'),
  
  -- Noah Schuster
  ((SELECT user_id FROM User WHERE email = 'noah.schuster@example.com'),
   'promotion', 'Exclusive deal: 20% off your next booking if you book by March 15!',
   FALSE, '2025-03-14 10:45:00'),
  
  -- Luisa Vogel
  ((SELECT user_id FROM User WHERE email = 'luisa.vogel@example.com'),
   'review', 'Your host has responded to your review of "Bavarian luxury apartment".',
   TRUE, '2025-03-16 17:30:00'),
  
  -- Julian Seidel
  ((SELECT user_id FROM User WHERE email = 'julian.seidel@example.com'),
   'system', 'New feature: You can now save your favorite listings to wishlists!',
   FALSE, '2025-03-18 09:00:00'),
  
  -- Marieke Hansen
  ((SELECT user_id FROM User WHERE email = 'marieke.hansen@example.com'),
   'booking', 'Your booking request for "Charming Altbau apartment" has been accepted.',
   TRUE, '2025-03-20 13:15:00'),
  
  -- David Lehmann
  ((SELECT user_id FROM User WHERE email = 'david.lehmann@example.com'),
   'payment', 'Payment reminder: Your booking for "Executive apartment" will be charged in 24 hours.',
   FALSE, '2025-03-22 11:50:00'),
  
  -- Sophie Koehler
  ((SELECT user_id FROM User WHERE email = 'sophie.koehler@example.com'),
   'promotion', 'Weekend special: 10% off all last-minute bookings in Berlin!',
   TRUE, '2025-03-24 14:05:00'),
  
  -- Emil Bergmann
  ((SELECT user_id FROM User WHERE email = 'emil.bergmann@example.com'),
   'review', 'You have received a new review from your host at "Authentic Black Forest chalet".',
   FALSE, '2025-03-26 10:25:00'),
  
  -- Maja Pohl
  ((SELECT user_id FROM User WHERE email = 'maja.pohl@example.com'),
   'system', 'Maintenance alert: The app will be unavailable for 1 hour on March 28 at 2 AM.',
   TRUE, '2025-03-27 18:40:00'),
  
  -- Leo Engel
  ((SELECT user_id FROM User WHERE email = 'leo.engel@example.com'),
   'booking', 'Your saved listing "Historic apartment in Leipzig" has a price drop!',
   FALSE, '2025-03-29 12:55:00'),
  
  -- Lena Mayer
  ((SELECT user_id FROM User WHERE email = 'lena.mayer@example.com'),
   'payment', 'Your payment method ending in 4242 will expire soon. Please update it.',
   TRUE, '2025-03-30 15:10:00'),
  
  -- Erik Winkler
  ((SELECT user_id FROM User WHERE email = 'erik.winkler@example.com'),
   'promotion', 'Easter special: Free cancellation on all bookings made before April 1!',
   FALSE, '2025-03-31 09:35:00'),
  
  -- Nele Gross
  ((SELECT user_id FROM User WHERE email = 'nele.gross@example.com'),
   'review', 'Thank you for your recent review! Your feedback helps us improve our service.',
   TRUE, '2025-03-31 16:20:00')
;

-- Insert PlatformPolicy Data
INSERT INTO PlatformPolicy (created_by_admin_id, title, content, creation_date, last_update_date)
VALUES
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'maximilian.mueller@example.com'),
  'Terms of Service', 'By using our platform, you agree to these terms and conditions...', '2023-01-15 09:00:00', '2023-06-15 11:30:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'sophie.schmidt@example.com'),
  'Privacy Policy', 'We are committed to protecting your personal information...', '2023-01-20 14:15:00', '2023-05-20 16:45:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'alexander.schneider@example.com'),
  'Cancellation Policy', 'Guests may cancel bookings according to the following rules...', '2023-02-05 10:30:00', '2023-07-10 09:20:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'marie.fischer@example.com'),
  'Community Guidelines', 'All users must adhere to our community standards...', '2023-02-12 11:45:00', '2023-04-18 14:10:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'paul.weber@example.com'),
  'Payment Policy', 'Accepted payment methods and processing times...', '2023-02-18 13:20:00', '2023-08-22 10:15:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'emilia.meyer@example.com'),
  'Host Requirements', 'Minimum standards for listing accommodations on our platform...', '2023-03-01 15:00:00', '2023-09-05 13:30:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'maximilian.mueller@example.com'),
  'Guest Responsibilities', 'Expectations for guests using our accommodations...', '2023-03-10 16:45:00', '2023-10-12 11:20:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'sophie.schmidt@example.com'),
  'Safety Standards', 'Our platform-wide safety requirements for all listings...', '2023-03-15 09:30:00', '2023-11-18 14:50:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'alexander.schneider@example.com'),
  'Refund Policy', 'Conditions under which refunds may be issued...', '2023-04-01 11:10:00', '2023-12-05 10:40:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'marie.fischer@example.com'),
  'Accessibility Policy', 'Our commitment to accessible accommodations...', '2023-04-10 14:25:00', '2024-01-15 09:15:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'paul.weber@example.com'),
  'Pricing Guidelines', 'Rules for hosts setting prices on our platform...', '2023-04-20 10:50:00', '2024-02-20 16:30:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'emilia.meyer@example.com'),
  'Review Policy', 'Standards for writing and moderating reviews...', '2023-05-05 13:15:00', '2024-03-10 11:45:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'maximilian.mueller@example.com'),
  'Dispute Resolution', 'Process for handling conflicts between users...', '2023-05-15 08:40:00', '2024-04-05 14:20:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'sophie.schmidt@example.com'),
  'Data Protection', 'How we collect, use, and protect your data...', '2023-05-25 16:05:00', '2024-05-12 10:10:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'alexander.schneider@example.com'),
  'Intellectual Property', 'Rules regarding content ownership on our platform...', '2023-06-05 09:20:00', '2024-06-18 15:30:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'marie.fischer@example.com'),
  'Insurance Requirements', 'Host insurance obligations for listed properties...', '2023-06-15 12:35:00', '2024-07-22 11:25:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'paul.weber@example.com'),
  'Pet Policy', 'Rules regarding pets in accommodations...', '2023-06-25 15:50:00', '2024-08-05 09:40:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'emilia.meyer@example.com'),
  'Seasonal Pricing Rules', 'Guidelines for seasonal rate adjustments...', '2023-07-05 10:05:00', '2024-09-15 14:15:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'maximilian.mueller@example.com'),
  'Emergency Procedures', 'Protocols for handling emergencies at accommodations...', '2023-07-15 13:30:00', '2024-10-25 16:50:00'),
  
  ((SELECT a.admin_id FROM User u JOIN Administrator a ON u.user_id = a.admin_id WHERE u.email = 'sophie.schmidt@example.com'),
  'Sustainability Policy', 'Our environmental responsibility commitments...', '2023-07-25 08:55:00', '2024-11-05 10:30:00');