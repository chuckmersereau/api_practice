--
-- PostgreSQL database dump
--


-- Dumped from database version 9.5.3
-- Dumped by pg_dump version 9.5.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account_list_entries; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE account_list_entries (
    id integer NOT NULL,
    account_list_id integer,
    designation_account_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: account_list_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_list_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_list_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_list_entries_id_seq OWNED BY account_list_entries.id;


--
-- Name: account_list_invites; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE account_list_invites (
    id integer NOT NULL,
    account_list_id integer,
    invited_by_user_id integer NOT NULL,
    code character varying(255) NOT NULL,
    recipient_email character varying(255) NOT NULL,
    accepted_by_user_id integer,
    accepted_at timestamp without time zone,
    cancelled_by_user_id integer
);


--
-- Name: account_list_invites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_list_invites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_list_invites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_list_invites_id_seq OWNED BY account_list_invites.id;


--
-- Name: account_list_users; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE account_list_users (
    id integer NOT NULL,
    user_id integer,
    account_list_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: account_list_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_list_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_list_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_list_users_id_seq OWNED BY account_list_users.id;


--
-- Name: account_lists; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE account_lists (
    id integer NOT NULL,
    name character varying(255),
    creator_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    settings text
);


--
-- Name: account_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE account_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE account_lists_id_seq OWNED BY account_lists.id;


--
-- Name: activities; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE activities (
    id integer NOT NULL,
    account_list_id integer,
    starred boolean DEFAULT false NOT NULL,
    location character varying(255),
    subject character varying(2000),
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    completed boolean DEFAULT false NOT NULL,
    activity_comments_count integer DEFAULT 0,
    activity_type character varying(255),
    result character varying(255),
    completed_at timestamp without time zone,
    notification_id integer,
    remote_id character varying(255),
    source character varying(255),
    next_action character varying(255),
    no_date boolean DEFAULT false
);


--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activities_id_seq OWNED BY activities.id;


--
-- Name: activity_comments; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE activity_comments (
    id integer NOT NULL,
    activity_id integer,
    person_id integer,
    body text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: activity_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_comments_id_seq OWNED BY activity_comments.id;


--
-- Name: activity_contacts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE activity_contacts (
    id integer NOT NULL,
    activity_id integer,
    contact_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: activity_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE activity_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE activity_contacts_id_seq OWNED BY activity_contacts.id;


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE addresses (
    id integer NOT NULL,
    addressable_id integer,
    street text,
    city character varying(255),
    state character varying(255),
    country character varying(255),
    postal_code character varying(255),
    location character varying(255),
    start_date date,
    end_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    primary_mailing_address boolean DEFAULT false,
    addressable_type character varying(255),
    remote_id character varying(255),
    seasonal boolean DEFAULT false,
    master_address_id integer NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    region character varying(255),
    metro_area character varying(255),
    historic boolean DEFAULT false,
    source character varying(255),
    source_donor_account_id integer
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;


--
-- Name: admin_impersonation_logs; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE admin_impersonation_logs (
    id integer NOT NULL,
    reason text NOT NULL,
    impersonator_id integer NOT NULL,
    impersonated_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: admin_impersonation_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE admin_impersonation_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_impersonation_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE admin_impersonation_logs_id_seq OWNED BY admin_impersonation_logs.id;


--
-- Name: appeal_contacts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE appeal_contacts (
    id integer NOT NULL,
    appeal_id integer,
    contact_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: appeal_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE appeal_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appeal_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE appeal_contacts_id_seq OWNED BY appeal_contacts.id;


--
-- Name: appeal_excluded_appeal_contacts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE appeal_excluded_appeal_contacts (
    id integer NOT NULL,
    appeal_id integer,
    contact_id integer,
    reasons text[]
);


--
-- Name: appeal_excluded_appeal_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE appeal_excluded_appeal_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appeal_excluded_appeal_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE appeal_excluded_appeal_contacts_id_seq OWNED BY appeal_excluded_appeal_contacts.id;


--
-- Name: appeals; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE appeals (
    id integer NOT NULL,
    name character varying(255),
    account_list_id integer,
    amount numeric(19,2),
    description text,
    end_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tnt_id integer
);


--
-- Name: appeals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE appeals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appeals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE appeals_id_seq OWNED BY appeals.id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE companies (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    street text,
    city character varying(255),
    state character varying(255),
    postal_code character varying(255),
    country character varying(255),
    phone_number character varying(255),
    master_company_id integer
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE companies_id_seq OWNED BY companies.id;


--
-- Name: company_partnerships; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE company_partnerships (
    id integer NOT NULL,
    account_list_id integer,
    company_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: company_partnerships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE company_partnerships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: company_partnerships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE company_partnerships_id_seq OWNED BY company_partnerships.id;


--
-- Name: company_positions; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE company_positions (
    id integer NOT NULL,
    person_id integer NOT NULL,
    company_id integer NOT NULL,
    start_date date,
    end_date date,
    "position" character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: company_positions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE company_positions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: company_positions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE company_positions_id_seq OWNED BY company_positions.id;


--
-- Name: contact_donor_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE contact_donor_accounts (
    id integer NOT NULL,
    contact_id integer,
    donor_account_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: contact_donor_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contact_donor_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_donor_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contact_donor_accounts_id_seq OWNED BY contact_donor_accounts.id;


--
-- Name: contact_notes_logs; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE contact_notes_logs (
    id integer NOT NULL,
    contact_id integer,
    recorded_on date,
    notes text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contact_notes_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contact_notes_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_notes_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contact_notes_logs_id_seq OWNED BY contact_notes_logs.id;


--
-- Name: contact_people; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE contact_people (
    id integer NOT NULL,
    contact_id integer,
    person_id integer,
    "primary" boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: contact_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contact_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contact_people_id_seq OWNED BY contact_people.id;


--
-- Name: contact_referrals; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE contact_referrals (
    id integer NOT NULL,
    referred_by_id integer,
    referred_to_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: contact_referrals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contact_referrals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contact_referrals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contact_referrals_id_seq OWNED BY contact_referrals.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE contacts (
    id integer NOT NULL,
    name character varying(255),
    account_list_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    pledge_amount numeric(19,2),
    status character varying(255),
    total_donations numeric(19,2),
    last_donation_date date,
    first_donation_date date,
    notes text,
    notes_saved_at timestamp without time zone,
    full_name character varying(255),
    greeting character varying(255),
    website character varying(1000),
    pledge_frequency numeric,
    pledge_start_date date,
    next_ask date,
    likely_to_give character varying(255),
    church_name text,
    send_newsletter character varying(255),
    direct_deposit boolean DEFAULT false NOT NULL,
    magazine boolean DEFAULT false NOT NULL,
    last_activity date,
    last_appointment date,
    last_letter date,
    last_phone_call date,
    last_pre_call date,
    last_thank date,
    pledge_received boolean DEFAULT false NOT NULL,
    tnt_id integer,
    not_duplicated_with character varying(2000),
    uncompleted_tasks_count integer DEFAULT 0 NOT NULL,
    prayer_letters_id character varying(255),
    timezone character varying(255),
    envelope_greeting character varying(255),
    no_appeals boolean,
    prayer_letters_params text,
    pls_id character varying(255),
    pledge_currency character varying(4),
    locale character varying(255)
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contacts_id_seq OWNED BY contacts.id;


--
-- Name: currency_aliases; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE currency_aliases (
    id integer NOT NULL,
    alias_code character varying(255) NOT NULL,
    rate_api_code character varying(255) NOT NULL,
    ratio numeric NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: currency_aliases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE currency_aliases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_aliases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE currency_aliases_id_seq OWNED BY currency_aliases.id;


--
-- Name: currency_rates; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE currency_rates (
    id integer NOT NULL,
    exchanged_on date NOT NULL,
    code character varying(255) NOT NULL,
    rate numeric(20,10) NOT NULL,
    source character varying(255) NOT NULL
);


--
-- Name: currency_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE currency_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE currency_rates_id_seq OWNED BY currency_rates.id;


--
-- Name: designation_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE designation_accounts (
    id integer NOT NULL,
    designation_number character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    organization_id integer,
    balance numeric(19,2),
    balance_updated_at timestamp without time zone,
    name character varying(255),
    staff_account_id character varying(255),
    chartfield character varying(255),
    active boolean DEFAULT true NOT NULL
);


--
-- Name: designation_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE designation_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: designation_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE designation_accounts_id_seq OWNED BY designation_accounts.id;


--
-- Name: designation_profile_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE designation_profile_accounts (
    id integer NOT NULL,
    designation_profile_id integer,
    designation_account_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: designation_profile_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE designation_profile_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: designation_profile_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE designation_profile_accounts_id_seq OWNED BY designation_profile_accounts.id;


--
-- Name: designation_profiles; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE designation_profiles (
    id integer NOT NULL,
    remote_id character varying(255),
    user_id integer NOT NULL,
    organization_id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    code character varying(255),
    balance numeric(19,2),
    balance_updated_at timestamp without time zone,
    account_list_id integer
);


--
-- Name: designation_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE designation_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: designation_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE designation_profiles_id_seq OWNED BY designation_profiles.id;


--
-- Name: donations; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE donations (
    id integer NOT NULL,
    remote_id character varying(255),
    donor_account_id integer,
    designation_account_id integer,
    motivation character varying(255),
    payment_method character varying(255),
    tendered_currency character varying(255),
    tendered_amount numeric(19,2),
    currency character varying(255),
    amount numeric(19,2),
    memo text,
    donation_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    payment_type character varying(255),
    channel character varying(255),
    appeal_id integer,
    appeal_amount numeric(19,2)
);


--
-- Name: donations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE donations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: donations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE donations_id_seq OWNED BY donations.id;


--
-- Name: donor_account_people; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE donor_account_people (
    id integer NOT NULL,
    donor_account_id integer,
    person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: donor_account_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE donor_account_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: donor_account_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE donor_account_people_id_seq OWNED BY donor_account_people.id;


--
-- Name: donor_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE donor_accounts (
    id integer NOT NULL,
    organization_id integer,
    account_number character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    master_company_id integer,
    total_donations numeric(19,2),
    last_donation_date date,
    first_donation_date date,
    donor_type character varying(20)
);


--
-- Name: donor_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE donor_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: donor_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE donor_accounts_id_seq OWNED BY donor_accounts.id;


--
-- Name: email_addresses; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE email_addresses (
    id integer NOT NULL,
    person_id integer,
    email character varying(255) NOT NULL,
    "primary" boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    remote_id character varying(255),
    location character varying(50),
    historic boolean DEFAULT false
);


--
-- Name: email_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE email_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE email_addresses_id_seq OWNED BY email_addresses.id;


--
-- Name: family_relationships; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE family_relationships (
    id integer NOT NULL,
    person_id integer,
    related_person_id integer,
    relationship character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: family_relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE family_relationships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: family_relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE family_relationships_id_seq OWNED BY family_relationships.id;


--
-- Name: google_contacts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE google_contacts (
    id integer NOT NULL,
    remote_id character varying(255),
    person_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    picture_etag character varying(255),
    picture_id integer,
    google_account_id integer,
    last_synced timestamp without time zone,
    last_etag character varying(255),
    last_data text,
    contact_id integer
);


--
-- Name: google_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE google_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: google_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE google_contacts_id_seq OWNED BY google_contacts.id;


--
-- Name: google_email_activities; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE google_email_activities (
    id integer NOT NULL,
    google_email_id integer,
    activity_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: google_email_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE google_email_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: google_email_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE google_email_activities_id_seq OWNED BY google_email_activities.id;


--
-- Name: google_emails; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE google_emails (
    id integer NOT NULL,
    google_account_id integer,
    google_email_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: google_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE google_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: google_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE google_emails_id_seq OWNED BY google_emails.id;


--
-- Name: google_events; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE google_events (
    id integer NOT NULL,
    activity_id integer,
    google_integration_id integer,
    google_event_id character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    calendar_id character varying(255)
);


--
-- Name: google_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE google_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: google_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE google_events_id_seq OWNED BY google_events.id;


--
-- Name: google_integrations; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE google_integrations (
    id integer NOT NULL,
    account_list_id integer,
    google_account_id integer,
    calendar_integration boolean DEFAULT false NOT NULL,
    calendar_integrations text,
    calendar_id character varying(255),
    calendar_name character varying(255),
    email_integration boolean DEFAULT false NOT NULL,
    contacts_integration boolean DEFAULT false NOT NULL,
    contacts_last_synced timestamp without time zone
);


--
-- Name: google_integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE google_integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: google_integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE google_integrations_id_seq OWNED BY google_integrations.id;


--
-- Name: help_requests; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE help_requests (
    id integer NOT NULL,
    name character varying(255),
    browser text,
    problem text,
    email character varying(255),
    file character varying(255),
    user_id integer,
    account_list_id integer,
    session text,
    user_preferences text,
    account_list_settings text,
    request_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: help_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE help_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: help_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE help_requests_id_seq OWNED BY help_requests.id;


--
-- Name: imports; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE imports (
    id integer NOT NULL,
    account_list_id integer,
    source character varying(255),
    file character varying(255),
    importing boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tags text,
    override boolean DEFAULT false NOT NULL,
    user_id integer,
    source_account_id integer,
    import_by_group boolean DEFAULT false,
    groups text,
    group_tags text,
    in_preview boolean DEFAULT false NOT NULL
);


--
-- Name: imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE imports_id_seq OWNED BY imports.id;


--
-- Name: mail_chimp_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE mail_chimp_accounts (
    id integer NOT NULL,
    api_key character varying(255),
    active boolean DEFAULT false,
    status_grouping_id character varying(255),
    primary_list_id character varying(255),
    account_list_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    webhook_token character varying(255),
    auto_log_campaigns boolean DEFAULT false NOT NULL,
    importing boolean DEFAULT false NOT NULL,
    status_interest_ids text,
    tags_grouping_id character varying(255),
    tags_interest_ids text
);


--
-- Name: mail_chimp_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mail_chimp_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_chimp_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mail_chimp_accounts_id_seq OWNED BY mail_chimp_accounts.id;


--
-- Name: mail_chimp_appeal_lists; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE mail_chimp_appeal_lists (
    id integer NOT NULL,
    mail_chimp_account_id integer NOT NULL,
    appeal_list_id character varying(255) NOT NULL,
    appeal_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mail_chimp_appeal_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mail_chimp_appeal_lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_chimp_appeal_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mail_chimp_appeal_lists_id_seq OWNED BY mail_chimp_appeal_lists.id;


--
-- Name: mail_chimp_members; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE mail_chimp_members (
    id integer NOT NULL,
    mail_chimp_account_id integer NOT NULL,
    list_id character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    status character varying(255),
    greeting character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    contact_locale character varying(255),
    tags character varying(255)[]
);


--
-- Name: mail_chimp_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mail_chimp_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_chimp_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mail_chimp_members_id_seq OWNED BY mail_chimp_members.id;


--
-- Name: master_addresses; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE master_addresses (
    id integer NOT NULL,
    street text,
    city character varying(255),
    state character varying(255),
    country character varying(255),
    postal_code character varying(255),
    verified boolean DEFAULT false NOT NULL,
    smarty_response text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    latitude character varying(255),
    longitude character varying(255)
);


--
-- Name: master_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_addresses_id_seq OWNED BY master_addresses.id;


--
-- Name: master_companies; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE master_companies (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: master_companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_companies_id_seq OWNED BY master_companies.id;


--
-- Name: master_people; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE master_people (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: master_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_people_id_seq OWNED BY master_people.id;


--
-- Name: master_person_donor_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE master_person_donor_accounts (
    id integer NOT NULL,
    master_person_id integer,
    donor_account_id integer,
    "primary" boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: master_person_donor_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_person_donor_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_person_donor_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_person_donor_accounts_id_seq OWNED BY master_person_donor_accounts.id;


--
-- Name: master_person_sources; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE master_person_sources (
    id integer NOT NULL,
    master_person_id integer,
    organization_id integer,
    remote_id character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: master_person_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE master_person_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: master_person_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE master_person_sources_id_seq OWNED BY master_person_sources.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE messages (
    id integer NOT NULL,
    from_id integer,
    to_id integer,
    subject character varying(255),
    body text,
    sent_at timestamp without time zone,
    source character varying(255),
    remote_id character varying(255),
    contact_id integer,
    account_list_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE messages_id_seq OWNED BY messages.id;


--
-- Name: name_male_ratios; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE name_male_ratios (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    male_ratio double precision NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: name_male_ratios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE name_male_ratios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: name_male_ratios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE name_male_ratios_id_seq OWNED BY name_male_ratios.id;


--
-- Name: nicknames; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE nicknames (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    nickname character varying(255) NOT NULL,
    source character varying(255),
    num_merges integer DEFAULT 0 NOT NULL,
    num_not_duplicates integer DEFAULT 0 NOT NULL,
    num_times_offered integer DEFAULT 0 NOT NULL,
    suggest_duplicates boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: nicknames_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE nicknames_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nicknames_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE nicknames_id_seq OWNED BY nicknames.id;


--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE notification_preferences (
    id integer NOT NULL,
    notification_type_id integer,
    account_list_id integer,
    actions text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notification_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notification_preferences_id_seq OWNED BY notification_preferences.id;


--
-- Name: notification_types; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE notification_types (
    id integer NOT NULL,
    type character varying(255),
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description_for_email text
);


--
-- Name: notification_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notification_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notification_types_id_seq OWNED BY notification_types.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE notifications (
    id integer NOT NULL,
    contact_id integer,
    notification_type_id integer,
    event_date timestamp without time zone,
    cleared boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    donation_id integer
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE organizations (
    id integer NOT NULL,
    name character varying(255),
    query_ini_url character varying(255),
    iso3166 character varying(255),
    minimum_gift_date character varying(255),
    logo character varying(255),
    code character varying(255),
    query_authentication boolean,
    account_help_url character varying(255),
    abbreviation character varying(255),
    org_help_email character varying(255),
    org_help_url character varying(255),
    org_help_url_description character varying(255),
    org_help_other text,
    request_profile_url character varying(255),
    staff_portal_url character varying(255),
    default_currency_code character varying(255),
    allow_passive_auth boolean,
    account_balance_url character varying(255),
    account_balance_params character varying(255),
    donations_url character varying(255),
    donations_params character varying(255),
    addresses_url character varying(255),
    addresses_params character varying(255),
    addresses_by_personids_url character varying(255),
    addresses_by_personids_params character varying(255),
    profiles_url character varying(255),
    profiles_params character varying(255),
    redirect_query_ini character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    api_class character varying(255),
    country character varying(255),
    uses_key_auth boolean DEFAULT false,
    locale character varying(255) DEFAULT 'en'::character varying NOT NULL
);


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE organizations_id_seq OWNED BY organizations.id;


--
-- Name: partner_status_logs; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE partner_status_logs (
    id integer NOT NULL,
    contact_id integer NOT NULL,
    recorded_on date NOT NULL,
    status character varying(255),
    pledge_amount numeric,
    pledge_frequency numeric,
    pledge_received boolean,
    pledge_start_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: partner_status_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE partner_status_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: partner_status_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE partner_status_logs_id_seq OWNED BY partner_status_logs.id;


--
-- Name: people; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE people (
    id integer NOT NULL,
    first_name character varying(255) NOT NULL,
    legal_first_name character varying(255),
    last_name character varying(255),
    birthday_month integer,
    birthday_year integer,
    birthday_day integer,
    anniversary_month integer,
    anniversary_year integer,
    anniversary_day integer,
    title character varying(255),
    suffix character varying(255),
    gender character varying(255),
    marital_status character varying(255),
    preferences text,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    master_person_id integer NOT NULL,
    middle_name character varying(255),
    access_token character varying(32),
    profession text,
    deceased boolean DEFAULT false NOT NULL,
    subscribed_to_updates boolean,
    optout_enewsletter boolean DEFAULT false,
    occupation character varying(255),
    employer character varying(255),
    not_duplicated_with character varying(2000),
    admin boolean DEFAULT false,
    developer boolean DEFAULT false
);


--
-- Name: people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE people_id_seq OWNED BY people.id;


--
-- Name: person_facebook_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE person_facebook_accounts (
    id integer NOT NULL,
    person_id integer NOT NULL,
    remote_id bigint,
    token character varying(255),
    token_expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    valid_token boolean DEFAULT false,
    first_name character varying(255),
    last_name character varying(255),
    authenticated boolean DEFAULT false NOT NULL,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone,
    username character varying(255)
);


--
-- Name: person_facebook_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE person_facebook_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_facebook_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE person_facebook_accounts_id_seq OWNED BY person_facebook_accounts.id;


--
-- Name: person_google_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE person_google_accounts (
    id integer NOT NULL,
    remote_id character varying(255),
    person_id integer,
    token character varying(255),
    refresh_token character varying(255),
    expires_at timestamp without time zone,
    valid_token boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    email character varying(255) NOT NULL,
    authenticated boolean DEFAULT false NOT NULL,
    "primary" boolean DEFAULT false,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone,
    last_email_sync timestamp without time zone,
    notified_failure boolean
);


--
-- Name: person_google_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE person_google_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_google_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE person_google_accounts_id_seq OWNED BY person_google_accounts.id;


--
-- Name: person_key_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE person_key_accounts (
    id integer NOT NULL,
    person_id integer,
    remote_id character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    email character varying(255),
    authenticated boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "primary" boolean DEFAULT false,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone
);


--
-- Name: person_key_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE person_key_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_key_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE person_key_accounts_id_seq OWNED BY person_key_accounts.id;


--
-- Name: person_linkedin_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE person_linkedin_accounts (
    id integer NOT NULL,
    person_id integer NOT NULL,
    remote_id character varying(255) NOT NULL,
    token character varying(255),
    secret character varying(255),
    token_expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    valid_token boolean DEFAULT false,
    first_name character varying(255),
    last_name character varying(255),
    authenticated boolean DEFAULT false NOT NULL,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone,
    public_url character varying(255)
);


--
-- Name: person_linkedin_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE person_linkedin_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_linkedin_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE person_linkedin_accounts_id_seq OWNED BY person_linkedin_accounts.id;


--
-- Name: person_organization_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE person_organization_accounts (
    id integer NOT NULL,
    person_id integer,
    organization_id integer,
    username character varying(255),
    password character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    remote_id character varying(255),
    authenticated boolean DEFAULT false NOT NULL,
    valid_credentials boolean DEFAULT false NOT NULL,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone,
    token character varying(255),
    locked_at timestamp without time zone,
    disable_downloads boolean DEFAULT false NOT NULL
);


--
-- Name: person_organization_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE person_organization_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_organization_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE person_organization_accounts_id_seq OWNED BY person_organization_accounts.id;


--
-- Name: person_relay_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE person_relay_accounts (
    id integer NOT NULL,
    person_id integer,
    relay_remote_id character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    email character varying(255),
    designation character varying(255),
    employee_id character varying(255),
    username character varying(255),
    authenticated boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "primary" boolean DEFAULT false,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone,
    remote_id character varying(255) NOT NULL
);


--
-- Name: person_relay_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE person_relay_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_relay_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE person_relay_accounts_id_seq OWNED BY person_relay_accounts.id;


--
-- Name: person_twitter_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE person_twitter_accounts (
    id integer NOT NULL,
    person_id integer NOT NULL,
    remote_id bigint NOT NULL,
    screen_name character varying(255),
    token character varying(255),
    secret character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    valid_token boolean DEFAULT false,
    authenticated boolean DEFAULT false NOT NULL,
    "primary" boolean DEFAULT false,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone
);


--
-- Name: person_twitter_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE person_twitter_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_twitter_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE person_twitter_accounts_id_seq OWNED BY person_twitter_accounts.id;


--
-- Name: person_websites; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE person_websites (
    id integer NOT NULL,
    person_id integer,
    url character varying(255),
    "primary" boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: person_websites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE person_websites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_websites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE person_websites_id_seq OWNED BY person_websites.id;


--
-- Name: phone_numbers; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE phone_numbers (
    id integer NOT NULL,
    person_id integer,
    number character varying(255),
    country_code character varying(255),
    location character varying(255),
    "primary" boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    remote_id character varying(255),
    historic boolean DEFAULT false
);


--
-- Name: phone_numbers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phone_numbers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phone_numbers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phone_numbers_id_seq OWNED BY phone_numbers.id;


--
-- Name: pictures; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE pictures (
    id integer NOT NULL,
    picture_of_id integer,
    picture_of_type character varying(255),
    image character varying(255),
    "primary" boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: pictures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pictures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pictures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pictures_id_seq OWNED BY pictures.id;


--
-- Name: pls_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE pls_accounts (
    id integer NOT NULL,
    account_list_id integer,
    oauth2_token character varying(255),
    valid_token boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: pls_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pls_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pls_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pls_accounts_id_seq OWNED BY pls_accounts.id;


--
-- Name: prayer_letters_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE prayer_letters_accounts (
    id integer NOT NULL,
    token character varying(255),
    secret character varying(255),
    valid_token boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    account_list_id integer,
    oauth2_token character varying(255)
);


--
-- Name: prayer_letters_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE prayer_letters_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prayer_letters_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE prayer_letters_accounts_id_seq OWNED BY prayer_letters_accounts.id;


--
-- Name: recurring_recommendation_results; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE recurring_recommendation_results (
    id integer NOT NULL,
    account_list_id integer,
    contact_id integer,
    result character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: recurring_recommendation_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE recurring_recommendation_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recurring_recommendation_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE recurring_recommendation_results_id_seq OWNED BY recurring_recommendation_results.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_id integer,
    taggable_type character varying(255),
    tagger_id integer,
    tagger_type character varying(255),
    context character varying(128),
    created_at timestamp without time zone
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE taggings_id_seq OWNED BY taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE tags (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -; Tablespace:
--

CREATE TABLE versions (
    id integer NOT NULL,
    item_type character varying(255) NOT NULL,
    item_id integer NOT NULL,
    event character varying(255) NOT NULL,
    whodunnit character varying(255),
    object text,
    related_object_type character varying(255),
    related_object_id integer,
    created_at timestamp without time zone
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_list_entries ALTER COLUMN id SET DEFAULT nextval('account_list_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_list_invites ALTER COLUMN id SET DEFAULT nextval('account_list_invites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_list_users ALTER COLUMN id SET DEFAULT nextval('account_list_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_lists ALTER COLUMN id SET DEFAULT nextval('account_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activities ALTER COLUMN id SET DEFAULT nextval('activities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_comments ALTER COLUMN id SET DEFAULT nextval('activity_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_contacts ALTER COLUMN id SET DEFAULT nextval('activity_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY admin_impersonation_logs ALTER COLUMN id SET DEFAULT nextval('admin_impersonation_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY appeal_contacts ALTER COLUMN id SET DEFAULT nextval('appeal_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY appeal_excluded_appeal_contacts ALTER COLUMN id SET DEFAULT nextval('appeal_excluded_appeal_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY appeals ALTER COLUMN id SET DEFAULT nextval('appeals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY companies ALTER COLUMN id SET DEFAULT nextval('companies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY company_partnerships ALTER COLUMN id SET DEFAULT nextval('company_partnerships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY company_positions ALTER COLUMN id SET DEFAULT nextval('company_positions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_donor_accounts ALTER COLUMN id SET DEFAULT nextval('contact_donor_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_notes_logs ALTER COLUMN id SET DEFAULT nextval('contact_notes_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_people ALTER COLUMN id SET DEFAULT nextval('contact_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_referrals ALTER COLUMN id SET DEFAULT nextval('contact_referrals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts ALTER COLUMN id SET DEFAULT nextval('contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY currency_aliases ALTER COLUMN id SET DEFAULT nextval('currency_aliases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY currency_rates ALTER COLUMN id SET DEFAULT nextval('currency_rates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY designation_accounts ALTER COLUMN id SET DEFAULT nextval('designation_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY designation_profile_accounts ALTER COLUMN id SET DEFAULT nextval('designation_profile_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY designation_profiles ALTER COLUMN id SET DEFAULT nextval('designation_profiles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY donations ALTER COLUMN id SET DEFAULT nextval('donations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY donor_account_people ALTER COLUMN id SET DEFAULT nextval('donor_account_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY donor_accounts ALTER COLUMN id SET DEFAULT nextval('donor_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_addresses ALTER COLUMN id SET DEFAULT nextval('email_addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY family_relationships ALTER COLUMN id SET DEFAULT nextval('family_relationships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_contacts ALTER COLUMN id SET DEFAULT nextval('google_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_email_activities ALTER COLUMN id SET DEFAULT nextval('google_email_activities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_emails ALTER COLUMN id SET DEFAULT nextval('google_emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_events ALTER COLUMN id SET DEFAULT nextval('google_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_integrations ALTER COLUMN id SET DEFAULT nextval('google_integrations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY help_requests ALTER COLUMN id SET DEFAULT nextval('help_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY imports ALTER COLUMN id SET DEFAULT nextval('imports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_chimp_accounts ALTER COLUMN id SET DEFAULT nextval('mail_chimp_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_chimp_appeal_lists ALTER COLUMN id SET DEFAULT nextval('mail_chimp_appeal_lists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_chimp_members ALTER COLUMN id SET DEFAULT nextval('mail_chimp_members_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_addresses ALTER COLUMN id SET DEFAULT nextval('master_addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_companies ALTER COLUMN id SET DEFAULT nextval('master_companies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_people ALTER COLUMN id SET DEFAULT nextval('master_people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_person_donor_accounts ALTER COLUMN id SET DEFAULT nextval('master_person_donor_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_person_sources ALTER COLUMN id SET DEFAULT nextval('master_person_sources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages ALTER COLUMN id SET DEFAULT nextval('messages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_male_ratios ALTER COLUMN id SET DEFAULT nextval('name_male_ratios_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY nicknames ALTER COLUMN id SET DEFAULT nextval('nicknames_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_preferences ALTER COLUMN id SET DEFAULT nextval('notification_preferences_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_types ALTER COLUMN id SET DEFAULT nextval('notification_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations ALTER COLUMN id SET DEFAULT nextval('organizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY partner_status_logs ALTER COLUMN id SET DEFAULT nextval('partner_status_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY people ALTER COLUMN id SET DEFAULT nextval('people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_facebook_accounts ALTER COLUMN id SET DEFAULT nextval('person_facebook_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_google_accounts ALTER COLUMN id SET DEFAULT nextval('person_google_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_key_accounts ALTER COLUMN id SET DEFAULT nextval('person_key_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_linkedin_accounts ALTER COLUMN id SET DEFAULT nextval('person_linkedin_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_organization_accounts ALTER COLUMN id SET DEFAULT nextval('person_organization_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_relay_accounts ALTER COLUMN id SET DEFAULT nextval('person_relay_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_twitter_accounts ALTER COLUMN id SET DEFAULT nextval('person_twitter_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_websites ALTER COLUMN id SET DEFAULT nextval('person_websites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phone_numbers ALTER COLUMN id SET DEFAULT nextval('phone_numbers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pictures ALTER COLUMN id SET DEFAULT nextval('pictures_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pls_accounts ALTER COLUMN id SET DEFAULT nextval('pls_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY prayer_letters_accounts ALTER COLUMN id SET DEFAULT nextval('prayer_letters_accounts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY recurring_recommendation_results ALTER COLUMN id SET DEFAULT nextval('recurring_recommendation_results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings ALTER COLUMN id SET DEFAULT nextval('taggings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: account_list_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY account_list_entries
    ADD CONSTRAINT account_list_entries_pkey PRIMARY KEY (id);


--
-- Name: account_list_invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY account_list_invites
    ADD CONSTRAINT account_list_invites_pkey PRIMARY KEY (id);


--
-- Name: account_list_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY account_list_users
    ADD CONSTRAINT account_list_users_pkey PRIMARY KEY (id);


--
-- Name: account_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY account_lists
    ADD CONSTRAINT account_lists_pkey PRIMARY KEY (id);


--
-- Name: activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: activity_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY activity_comments
    ADD CONSTRAINT activity_comments_pkey PRIMARY KEY (id);


--
-- Name: activity_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY activity_contacts
    ADD CONSTRAINT activity_contacts_pkey PRIMARY KEY (id);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);

ALTER TABLE addresses CLUSTER ON addresses_pkey;


--
-- Name: admin_impersonation_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY admin_impersonation_logs
    ADD CONSTRAINT admin_impersonation_logs_pkey PRIMARY KEY (id);


--
-- Name: appeal_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY appeal_contacts
    ADD CONSTRAINT appeal_contacts_pkey PRIMARY KEY (id);


--
-- Name: appeal_excluded_appeal_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY appeal_excluded_appeal_contacts
    ADD CONSTRAINT appeal_excluded_appeal_contacts_pkey PRIMARY KEY (id);


--
-- Name: appeals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY appeals
    ADD CONSTRAINT appeals_pkey PRIMARY KEY (id);


--
-- Name: companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_partnerships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY company_partnerships
    ADD CONSTRAINT company_partnerships_pkey PRIMARY KEY (id);


--
-- Name: company_positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY company_positions
    ADD CONSTRAINT company_positions_pkey PRIMARY KEY (id);


--
-- Name: contact_donor_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY contact_donor_accounts
    ADD CONSTRAINT contact_donor_accounts_pkey PRIMARY KEY (id);


--
-- Name: contact_notes_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY contact_notes_logs
    ADD CONSTRAINT contact_notes_logs_pkey PRIMARY KEY (id);


--
-- Name: contact_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY contact_people
    ADD CONSTRAINT contact_people_pkey PRIMARY KEY (id);


--
-- Name: contact_referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY contact_referrals
    ADD CONSTRAINT contact_referrals_pkey PRIMARY KEY (id);


--
-- Name: contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: currency_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY currency_aliases
    ADD CONSTRAINT currency_aliases_pkey PRIMARY KEY (id);


--
-- Name: currency_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY currency_rates
    ADD CONSTRAINT currency_rates_pkey PRIMARY KEY (id);


--
-- Name: designation_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY designation_accounts
    ADD CONSTRAINT designation_accounts_pkey PRIMARY KEY (id);


--
-- Name: designation_profile_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY designation_profile_accounts
    ADD CONSTRAINT designation_profile_accounts_pkey PRIMARY KEY (id);


--
-- Name: designation_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY designation_profiles
    ADD CONSTRAINT designation_profiles_pkey PRIMARY KEY (id);


--
-- Name: donations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY donations
    ADD CONSTRAINT donations_pkey PRIMARY KEY (id);


--
-- Name: donor_account_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY donor_account_people
    ADD CONSTRAINT donor_account_people_pkey PRIMARY KEY (id);


--
-- Name: donor_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY donor_accounts
    ADD CONSTRAINT donor_accounts_pkey PRIMARY KEY (id);


--
-- Name: email_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY email_addresses
    ADD CONSTRAINT email_addresses_pkey PRIMARY KEY (id);


--
-- Name: family_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY family_relationships
    ADD CONSTRAINT family_relationships_pkey PRIMARY KEY (id);


--
-- Name: google_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY google_contacts
    ADD CONSTRAINT google_contacts_pkey PRIMARY KEY (id);


--
-- Name: google_email_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY google_email_activities
    ADD CONSTRAINT google_email_activities_pkey PRIMARY KEY (id);


--
-- Name: google_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY google_emails
    ADD CONSTRAINT google_emails_pkey PRIMARY KEY (id);


--
-- Name: google_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY google_events
    ADD CONSTRAINT google_events_pkey PRIMARY KEY (id);


--
-- Name: google_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY google_integrations
    ADD CONSTRAINT google_integrations_pkey PRIMARY KEY (id);


--
-- Name: help_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY help_requests
    ADD CONSTRAINT help_requests_pkey PRIMARY KEY (id);


--
-- Name: imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: mail_chimp_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY mail_chimp_accounts
    ADD CONSTRAINT mail_chimp_accounts_pkey PRIMARY KEY (id);


--
-- Name: mail_chimp_appeal_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY mail_chimp_appeal_lists
    ADD CONSTRAINT mail_chimp_appeal_lists_pkey PRIMARY KEY (id);


--
-- Name: mail_chimp_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY mail_chimp_members
    ADD CONSTRAINT mail_chimp_members_pkey PRIMARY KEY (id);


--
-- Name: master_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY master_addresses
    ADD CONSTRAINT master_addresses_pkey PRIMARY KEY (id);


--
-- Name: master_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY master_companies
    ADD CONSTRAINT master_companies_pkey PRIMARY KEY (id);


--
-- Name: master_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY master_people
    ADD CONSTRAINT master_people_pkey PRIMARY KEY (id);


--
-- Name: master_person_donor_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY master_person_donor_accounts
    ADD CONSTRAINT master_person_donor_accounts_pkey PRIMARY KEY (id);


--
-- Name: master_person_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY master_person_sources
    ADD CONSTRAINT master_person_sources_pkey PRIMARY KEY (id);


--
-- Name: messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: name_male_ratios_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY name_male_ratios
    ADD CONSTRAINT name_male_ratios_pkey PRIMARY KEY (id);


--
-- Name: nicknames_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY nicknames
    ADD CONSTRAINT nicknames_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: notification_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY notification_types
    ADD CONSTRAINT notification_types_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: partner_status_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY partner_status_logs
    ADD CONSTRAINT partner_status_logs_pkey PRIMARY KEY (id);


--
-- Name: people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: person_facebook_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY person_facebook_accounts
    ADD CONSTRAINT person_facebook_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_google_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY person_google_accounts
    ADD CONSTRAINT person_google_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_key_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY person_key_accounts
    ADD CONSTRAINT person_key_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_linkedin_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY person_linkedin_accounts
    ADD CONSTRAINT person_linkedin_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_organization_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY person_organization_accounts
    ADD CONSTRAINT person_organization_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_relay_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY person_relay_accounts
    ADD CONSTRAINT person_relay_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_twitter_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY person_twitter_accounts
    ADD CONSTRAINT person_twitter_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_websites_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY person_websites
    ADD CONSTRAINT person_websites_pkey PRIMARY KEY (id);


--
-- Name: phone_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY phone_numbers
    ADD CONSTRAINT phone_numbers_pkey PRIMARY KEY (id);


--
-- Name: pictures_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY pictures
    ADD CONSTRAINT pictures_pkey PRIMARY KEY (id);


--
-- Name: pls_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY pls_accounts
    ADD CONSTRAINT pls_accounts_pkey PRIMARY KEY (id);


--
-- Name: prayer_letters_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY prayer_letters_accounts
    ADD CONSTRAINT prayer_letters_accounts_pkey PRIMARY KEY (id);


--
-- Name: recurring_recommendation_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY recurring_recommendation_results
    ADD CONSTRAINT recurring_recommendation_results_pkey PRIMARY KEY (id);


--
-- Name: taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace:
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: INDEX_TAGGINGS_ON_TAGGABLE_ID; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX "INDEX_TAGGINGS_ON_TAGGABLE_ID" ON taggings USING btree (taggable_id);


--
-- Name: all_fields; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX all_fields ON master_addresses USING btree (street, city, state, country, postal_code);


--
-- Name: designation_p_to_a; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX designation_p_to_a ON designation_profile_accounts USING btree (designation_profile_id, designation_account_id);


--
-- Name: index_account_list_entries_on_designation_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_account_list_entries_on_designation_account_id ON account_list_entries USING btree (designation_account_id);


--
-- Name: index_account_list_users_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_account_list_users_on_account_list_id ON account_list_users USING btree (account_list_id);


--
-- Name: index_account_list_users_on_user_id_and_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_account_list_users_on_user_id_and_account_list_id ON account_list_users USING btree (user_id, account_list_id);


--
-- Name: index_account_lists_on_creator_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_account_lists_on_creator_id ON account_lists USING btree (creator_id);


--
-- Name: index_activities_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_activities_on_account_list_id ON activities USING btree (account_list_id);


--
-- Name: index_activities_on_activity_type; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_activities_on_activity_type ON activities USING btree (activity_type);


--
-- Name: index_activities_on_completed; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_activities_on_completed ON activities USING btree (completed);


--
-- Name: index_activities_on_completed_at; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_activities_on_completed_at ON activities USING btree (completed_at);


--
-- Name: index_activities_on_notification_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_activities_on_notification_id ON activities USING btree (notification_id);


--
-- Name: index_activities_on_start_at; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_activities_on_start_at ON activities USING btree (start_at);


--
-- Name: index_activity_comments_on_activity_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_activity_comments_on_activity_id ON activity_comments USING btree (activity_id);


--
-- Name: index_activity_comments_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_activity_comments_on_person_id ON activity_comments USING btree (person_id);


--
-- Name: index_activity_contacts_on_activity_id_and_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_activity_contacts_on_activity_id_and_contact_id ON activity_contacts USING btree (activity_id, contact_id);


--
-- Name: index_activity_contacts_on_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_activity_contacts_on_contact_id ON activity_contacts USING btree (contact_id);


--
-- Name: index_activity_contacts_on_contact_id_and_activity_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_activity_contacts_on_contact_id_and_activity_id ON activity_contacts USING btree (contact_id, activity_id);


--
-- Name: index_addresses_on_addressable_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_addresses_on_addressable_id ON addresses USING btree (addressable_id);


--
-- Name: index_addresses_on_lower_city; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_addresses_on_lower_city ON addresses USING btree (lower((city)::text));


--
-- Name: index_addresses_on_master_address_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_addresses_on_master_address_id ON addresses USING btree (master_address_id);


--
-- Name: index_addresses_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_addresses_on_remote_id ON addresses USING btree (remote_id);


--
-- Name: index_appeal_contacts_on_appeal_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_appeal_contacts_on_appeal_id ON appeal_contacts USING btree (appeal_id);


--
-- Name: index_appeal_contacts_on_appeal_id_and_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_appeal_contacts_on_appeal_id_and_contact_id ON appeal_contacts USING btree (appeal_id, contact_id);


--
-- Name: index_appeal_contacts_on_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_appeal_contacts_on_contact_id ON appeal_contacts USING btree (contact_id);


--
-- Name: index_appeals_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_appeals_on_account_list_id ON appeals USING btree (account_list_id);


--
-- Name: index_company_partnerships_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_company_partnerships_on_company_id ON company_partnerships USING btree (company_id);


--
-- Name: index_company_positions_on_company_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_company_positions_on_company_id ON company_positions USING btree (company_id);


--
-- Name: index_company_positions_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_company_positions_on_person_id ON company_positions USING btree (person_id);


--
-- Name: index_company_positions_on_start_date; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_company_positions_on_start_date ON company_positions USING btree (start_date);


--
-- Name: index_contact_donor_accounts_on_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_contact_donor_accounts_on_contact_id ON contact_donor_accounts USING btree (contact_id);


--
-- Name: index_contact_donor_accounts_on_donor_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_contact_donor_accounts_on_donor_account_id ON contact_donor_accounts USING btree (donor_account_id);


--
-- Name: index_contact_notes_logs_on_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_contact_notes_logs_on_contact_id ON contact_notes_logs USING btree (contact_id);


--
-- Name: index_contact_notes_logs_on_recorded_on; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_contact_notes_logs_on_recorded_on ON contact_notes_logs USING btree (recorded_on);


--
-- Name: index_contact_people_on_contact_id_and_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_contact_people_on_contact_id_and_person_id ON contact_people USING btree (contact_id, person_id);


--
-- Name: index_contact_people_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_contact_people_on_person_id ON contact_people USING btree (person_id);


--
-- Name: index_contact_referrals_on_referred_to_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_contact_referrals_on_referred_to_id ON contact_referrals USING btree (referred_to_id);


--
-- Name: index_contacts_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_contacts_on_account_list_id ON contacts USING btree (account_list_id);


--
-- Name: index_contacts_on_last_donation_date; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_contacts_on_last_donation_date ON contacts USING btree (last_donation_date);


--
-- Name: index_contacts_on_tnt_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_contacts_on_tnt_id ON contacts USING btree (tnt_id);


--
-- Name: index_contacts_on_total_donations; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_contacts_on_total_donations ON contacts USING btree (total_donations);


--
-- Name: index_currency_rates_on_code; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_currency_rates_on_code ON currency_rates USING btree (code);


--
-- Name: index_currency_rates_on_code_and_exchanged_on; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_currency_rates_on_code_and_exchanged_on ON currency_rates USING btree (code, exchanged_on);


--
-- Name: index_currency_rates_on_exchanged_on; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_currency_rates_on_exchanged_on ON currency_rates USING btree (exchanged_on);


--
-- Name: index_designation_profiles_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_designation_profiles_on_account_list_id ON designation_profiles USING btree (account_list_id);


--
-- Name: index_designation_profiles_on_organization_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_designation_profiles_on_organization_id ON designation_profiles USING btree (organization_id);


--
-- Name: index_donations_on_appeal_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_donations_on_appeal_id ON donations USING btree (appeal_id);


--
-- Name: index_donations_on_donation_date; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_donations_on_donation_date ON donations USING btree (donation_date);


--
-- Name: index_donations_on_donor_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_donations_on_donor_account_id ON donations USING btree (donor_account_id);


--
-- Name: index_donor_account_people_on_donor_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_donor_account_people_on_donor_account_id ON donor_account_people USING btree (donor_account_id);


--
-- Name: index_donor_account_people_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_donor_account_people_on_person_id ON donor_account_people USING btree (person_id);


--
-- Name: index_donor_accounts_on_last_donation_date; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_donor_accounts_on_last_donation_date ON donor_accounts USING btree (last_donation_date);


--
-- Name: index_donor_accounts_on_organization_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_donor_accounts_on_organization_id ON donor_accounts USING btree (organization_id);


--
-- Name: index_donor_accounts_on_organization_id_and_account_number; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_donor_accounts_on_organization_id_and_account_number ON donor_accounts USING btree (organization_id, account_number);


--
-- Name: index_donor_accounts_on_total_donations; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_donor_accounts_on_total_donations ON donor_accounts USING btree (total_donations);


--
-- Name: index_email_addresses_on_email_and_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_email_addresses_on_email_and_person_id ON email_addresses USING btree (email, person_id);


--
-- Name: index_email_addresses_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_email_addresses_on_person_id ON email_addresses USING btree (person_id);


--
-- Name: index_email_addresses_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_email_addresses_on_remote_id ON email_addresses USING btree (remote_id);


--
-- Name: index_excluded_appeal_contacts_on_appeal_and_contact; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_excluded_appeal_contacts_on_appeal_and_contact ON appeal_excluded_appeal_contacts USING btree (appeal_id, contact_id);


--
-- Name: index_family_relationships_on_person_id_and_related_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_family_relationships_on_person_id_and_related_person_id ON family_relationships USING btree (person_id, related_person_id);


--
-- Name: index_family_relationships_on_related_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_family_relationships_on_related_person_id ON family_relationships USING btree (related_person_id);


--
-- Name: index_google_contacts_on_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_contacts_on_contact_id ON google_contacts USING btree (contact_id);


--
-- Name: index_google_contacts_on_google_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_contacts_on_google_account_id ON google_contacts USING btree (google_account_id);


--
-- Name: index_google_contacts_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_contacts_on_person_id ON google_contacts USING btree (person_id);


--
-- Name: index_google_contacts_on_person_id_and_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_contacts_on_person_id_and_contact_id ON google_contacts USING btree (person_id, contact_id);


--
-- Name: index_google_contacts_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_contacts_on_remote_id ON google_contacts USING btree (remote_id);


--
-- Name: index_google_email_activities_on_activity_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_email_activities_on_activity_id ON google_email_activities USING btree (activity_id);


--
-- Name: index_google_email_activities_on_google_email_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_email_activities_on_google_email_id ON google_email_activities USING btree (google_email_id);


--
-- Name: index_google_emails_on_google_account_id_and_google_email_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_emails_on_google_account_id_and_google_email_id ON google_emails USING btree (google_account_id, google_email_id);


--
-- Name: index_google_events_on_activity_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_events_on_activity_id ON google_events USING btree (activity_id);


--
-- Name: index_google_events_on_google_integration_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_events_on_google_integration_id ON google_events USING btree (google_integration_id);


--
-- Name: index_google_integrations_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_integrations_on_account_list_id ON google_integrations USING btree (account_list_id);


--
-- Name: index_google_integrations_on_google_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_google_integrations_on_google_account_id ON google_integrations USING btree (google_account_id);


--
-- Name: index_imports_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_imports_on_account_list_id ON imports USING btree (account_list_id);


--
-- Name: index_imports_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_imports_on_user_id ON imports USING btree (user_id);


--
-- Name: index_mail_chimp_accounts_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_mail_chimp_accounts_on_account_list_id ON mail_chimp_accounts USING btree (account_list_id);


--
-- Name: index_mail_chimp_appeal_lists_on_appeal_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_mail_chimp_appeal_lists_on_appeal_list_id ON mail_chimp_appeal_lists USING btree (appeal_list_id);


--
-- Name: index_mail_chimp_appeal_lists_on_mail_chimp_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_mail_chimp_appeal_lists_on_mail_chimp_account_id ON mail_chimp_appeal_lists USING btree (mail_chimp_account_id);


--
-- Name: index_mail_chimp_members_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_mail_chimp_members_on_email ON mail_chimp_members USING btree (email);


--
-- Name: index_mail_chimp_members_on_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_mail_chimp_members_on_list_id ON mail_chimp_members USING btree (list_id);


--
-- Name: index_mail_chimp_members_on_mail_chimp_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_mail_chimp_members_on_mail_chimp_account_id ON mail_chimp_members USING btree (mail_chimp_account_id);


--
-- Name: index_master_addresses_on_city; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_master_addresses_on_city ON master_addresses USING btree (city);


--
-- Name: index_master_addresses_on_country; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_master_addresses_on_country ON master_addresses USING btree (country);


--
-- Name: index_master_addresses_on_latitude; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_master_addresses_on_latitude ON master_addresses USING btree (latitude);


--
-- Name: index_master_addresses_on_postal_code; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_master_addresses_on_postal_code ON master_addresses USING btree (postal_code);


--
-- Name: index_master_addresses_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_master_addresses_on_state ON master_addresses USING btree (state);


--
-- Name: index_master_addresses_on_street; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_master_addresses_on_street ON master_addresses USING btree (street);


--
-- Name: index_master_person_donor_accounts_on_donor_account_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_master_person_donor_accounts_on_donor_account_id ON master_person_donor_accounts USING btree (donor_account_id);


--
-- Name: index_master_person_sources_on_master_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_master_person_sources_on_master_person_id ON master_person_sources USING btree (master_person_id);


--
-- Name: index_messages_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_messages_on_account_list_id ON messages USING btree (account_list_id);


--
-- Name: index_messages_on_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_messages_on_contact_id ON messages USING btree (contact_id);


--
-- Name: index_messages_on_from_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_messages_on_from_id ON messages USING btree (from_id);


--
-- Name: index_messages_on_to_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_messages_on_to_id ON messages USING btree (to_id);


--
-- Name: index_name_male_ratios_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_name_male_ratios_on_name ON name_male_ratios USING btree (name);


--
-- Name: index_nicknames_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_nicknames_on_name ON nicknames USING btree (name);


--
-- Name: index_nicknames_on_name_and_nickname; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_nicknames_on_name_and_nickname ON nicknames USING btree (name, nickname);


--
-- Name: index_nicknames_on_nickname; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_nicknames_on_nickname ON nicknames USING btree (nickname);


--
-- Name: index_notification_preferences_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_notification_preferences_on_account_list_id ON notification_preferences USING btree (account_list_id);


--
-- Name: index_notification_preferences_on_notification_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_notification_preferences_on_notification_type_id ON notification_preferences USING btree (notification_type_id);


--
-- Name: index_notifications_on_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_notifications_on_contact_id ON notifications USING btree (contact_id);


--
-- Name: index_notifications_on_donation_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_notifications_on_donation_id ON notifications USING btree (donation_id);


--
-- Name: index_notifications_on_notification_type_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_notifications_on_notification_type_id ON notifications USING btree (notification_type_id);


--
-- Name: index_organizations_on_query_ini_url; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_organizations_on_query_ini_url ON organizations USING btree (query_ini_url);


--
-- Name: index_partner_status_logs_on_contact_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_partner_status_logs_on_contact_id ON partner_status_logs USING btree (contact_id);


--
-- Name: index_partner_status_logs_on_recorded_on; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_partner_status_logs_on_recorded_on ON partner_status_logs USING btree (recorded_on);


--
-- Name: index_people_on_access_token; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_people_on_access_token ON people USING btree (access_token);


--
-- Name: index_people_on_first_name; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_people_on_first_name ON people USING btree (first_name);


--
-- Name: index_people_on_last_name; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_people_on_last_name ON people USING btree (last_name);


--
-- Name: index_people_on_master_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_people_on_master_person_id ON people USING btree (master_person_id);


--
-- Name: index_person_facebook_accounts_on_person_id_and_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_person_facebook_accounts_on_person_id_and_remote_id ON person_facebook_accounts USING btree (person_id, remote_id);


--
-- Name: index_person_facebook_accounts_on_person_id_and_username; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_person_facebook_accounts_on_person_id_and_username ON person_facebook_accounts USING btree (person_id, username);


--
-- Name: index_person_facebook_accounts_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_person_facebook_accounts_on_remote_id ON person_facebook_accounts USING btree (remote_id);


--
-- Name: index_person_google_accounts_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_person_google_accounts_on_person_id ON person_google_accounts USING btree (person_id);


--
-- Name: index_person_google_accounts_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_person_google_accounts_on_remote_id ON person_google_accounts USING btree (remote_id);


--
-- Name: index_person_key_accounts_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_person_key_accounts_on_person_id ON person_key_accounts USING btree (person_id);


--
-- Name: index_person_key_accounts_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_person_key_accounts_on_remote_id ON person_key_accounts USING btree (remote_id);


--
-- Name: index_person_linkedin_accounts_on_person_id_and_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_person_linkedin_accounts_on_person_id_and_remote_id ON person_linkedin_accounts USING btree (person_id, remote_id);


--
-- Name: index_person_linkedin_accounts_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_person_linkedin_accounts_on_remote_id ON person_linkedin_accounts USING btree (remote_id);


--
-- Name: index_person_relay_accounts_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_person_relay_accounts_on_person_id ON person_relay_accounts USING btree (person_id);


--
-- Name: index_person_relay_accounts_on_relay_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_person_relay_accounts_on_relay_remote_id ON person_relay_accounts USING btree (relay_remote_id);


--
-- Name: index_person_twitter_accounts_on_person_id_and_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_person_twitter_accounts_on_person_id_and_remote_id ON person_twitter_accounts USING btree (person_id, remote_id);


--
-- Name: index_person_twitter_accounts_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_person_twitter_accounts_on_remote_id ON person_twitter_accounts USING btree (remote_id);


--
-- Name: index_person_websites_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_person_websites_on_person_id ON person_websites USING btree (person_id);


--
-- Name: index_phone_numbers_on_person_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_phone_numbers_on_person_id ON phone_numbers USING btree (person_id);


--
-- Name: index_phone_numbers_on_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_phone_numbers_on_remote_id ON phone_numbers USING btree (remote_id);


--
-- Name: index_pls_accounts_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_pls_accounts_on_account_list_id ON pls_accounts USING btree (account_list_id);


--
-- Name: index_prayer_letters_accounts_on_account_list_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_prayer_letters_accounts_on_account_list_id ON prayer_letters_accounts USING btree (account_list_id);


--
-- Name: index_remote_id_on_person_relay_account; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_remote_id_on_person_relay_account ON person_relay_accounts USING btree (lower((relay_remote_id)::text));


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX index_tags_on_name ON tags USING btree (name);


--
-- Name: index_versions_on_item_type; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_versions_on_item_type ON versions USING btree (item_type, event, related_object_type, related_object_id, created_at, item_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_versions_on_item_type_and_item_id ON versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_whodunnit; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX index_versions_on_whodunnit ON versions USING btree (whodunnit);


--
-- Name: mail_chimp_members_email_list_account_uniq; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX mail_chimp_members_email_list_account_uniq ON mail_chimp_members USING btree (mail_chimp_account_id, list_id, email);


--
-- Name: notification_index; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX notification_index ON notifications USING btree (contact_id, notification_type_id, donation_id);


--
-- Name: organization_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX organization_remote_id ON master_person_sources USING btree (organization_id, remote_id);


--
-- Name: person_account; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX person_account ON master_person_donor_accounts USING btree (master_person_id, donor_account_id);


--
-- Name: person_relay_accounts_on_lower_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX person_relay_accounts_on_lower_remote_id ON person_relay_accounts USING btree (lower((remote_id)::text));


--
-- Name: picture_of; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX picture_of ON pictures USING btree (picture_of_id, picture_of_type);


--
-- Name: referrals; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX referrals ON contact_referrals USING btree (referred_by_id, referred_to_id);


--
-- Name: related_object_index; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX related_object_index ON versions USING btree (item_type, related_object_type, related_object_id, created_at);


--
-- Name: taggings_idx; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX taggings_idx ON taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);


--
-- Name: tags_on_lower_name; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE INDEX tags_on_lower_name ON tags USING btree (lower((name)::text));


--
-- Name: unique_account; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX unique_account ON account_list_entries USING btree (account_list_id, designation_account_id);


--
-- Name: unique_company_account; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX unique_company_account ON company_partnerships USING btree (account_list_id, company_id);


--
-- Name: unique_designation_org; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX unique_designation_org ON designation_accounts USING btree (organization_id, designation_number);


--
-- Name: unique_donation_designation; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX unique_donation_designation ON donations USING btree (designation_account_id, remote_id);


--
-- Name: unique_remote_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX unique_remote_id ON designation_profiles USING btree (user_id, organization_id, remote_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: user_id_and_organization_id; Type: INDEX; Schema: public; Owner: -; Tablespace:
--

CREATE UNIQUE INDEX user_id_and_organization_id ON person_organization_accounts USING btree (person_id, organization_id);


--
-- Name: appeal_excluded_appeal_contacts_appeal_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appeal_excluded_appeal_contacts
    ADD CONSTRAINT appeal_excluded_appeal_contacts_appeal_id_fk FOREIGN KEY (appeal_id) REFERENCES appeals(id) ON DELETE CASCADE;


--
-- Name: appeal_excluded_appeal_contacts_contact_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appeal_excluded_appeal_contacts
    ADD CONSTRAINT appeal_excluded_appeal_contacts_contact_id_fk FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE;


--
-- Name: master_person_sources_master_person_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_person_sources
    ADD CONSTRAINT master_person_sources_master_person_id_fk FOREIGN KEY (master_person_id) REFERENCES master_people(id);


--
-- Name: people_master_person_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_master_person_id_fk FOREIGN KEY (master_person_id) REFERENCES master_people(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20120201152759');

INSERT INTO schema_migrations (version) VALUES ('20120201225214');

INSERT INTO schema_migrations (version) VALUES ('20120202171204');

INSERT INTO schema_migrations (version) VALUES ('20120202171236');

INSERT INTO schema_migrations (version) VALUES ('20120202200843');

INSERT INTO schema_migrations (version) VALUES ('20120202203409');

INSERT INTO schema_migrations (version) VALUES ('20120202215030');

INSERT INTO schema_migrations (version) VALUES ('20120208190407');

INSERT INTO schema_migrations (version) VALUES ('20120209221107');

INSERT INTO schema_migrations (version) VALUES ('20120215143944');

INSERT INTO schema_migrations (version) VALUES ('20120219080953');

INSERT INTO schema_migrations (version) VALUES ('20120219134153');

INSERT INTO schema_migrations (version) VALUES ('20120224195315');

INSERT INTO schema_migrations (version) VALUES ('20120224200413');

INSERT INTO schema_migrations (version) VALUES ('20120228124823');

INSERT INTO schema_migrations (version) VALUES ('20120229194355');

INSERT INTO schema_migrations (version) VALUES ('20120229195010');

INSERT INTO schema_migrations (version) VALUES ('20120229195155');

INSERT INTO schema_migrations (version) VALUES ('20120302145102');

INSERT INTO schema_migrations (version) VALUES ('20120302190237');

INSERT INTO schema_migrations (version) VALUES ('20120306213318');

INSERT INTO schema_migrations (version) VALUES ('20120306220807');

INSERT INTO schema_migrations (version) VALUES ('20120308195946');

INSERT INTO schema_migrations (version) VALUES ('20120308211617');

INSERT INTO schema_migrations (version) VALUES ('20120309134945');

INSERT INTO schema_migrations (version) VALUES ('20120309135317');

INSERT INTO schema_migrations (version) VALUES ('20120309152420');

INSERT INTO schema_migrations (version) VALUES ('20120309171322');

INSERT INTO schema_migrations (version) VALUES ('20120309211002');

INSERT INTO schema_migrations (version) VALUES ('20120309220159');

INSERT INTO schema_migrations (version) VALUES ('20120309222504');

INSERT INTO schema_migrations (version) VALUES ('20120309224231');

INSERT INTO schema_migrations (version) VALUES ('20120312174302');

INSERT INTO schema_migrations (version) VALUES ('20120313144846');

INSERT INTO schema_migrations (version) VALUES ('20120314141926');

INSERT INTO schema_migrations (version) VALUES ('20120314162022');

INSERT INTO schema_migrations (version) VALUES ('20120314202116');

INSERT INTO schema_migrations (version) VALUES ('20120314205616');

INSERT INTO schema_migrations (version) VALUES ('20120314212559');

INSERT INTO schema_migrations (version) VALUES ('20120315201646');

INSERT INTO schema_migrations (version) VALUES ('20120323163229');

INSERT INTO schema_migrations (version) VALUES ('20120326194920');

INSERT INTO schema_migrations (version) VALUES ('20120328193356');

INSERT INTO schema_migrations (version) VALUES ('20120328212222');

INSERT INTO schema_migrations (version) VALUES ('20120328212812');

INSERT INTO schema_migrations (version) VALUES ('20120329145102');

INSERT INTO schema_migrations (version) VALUES ('20120330025557');

INSERT INTO schema_migrations (version) VALUES ('20120330150711');

INSERT INTO schema_migrations (version) VALUES ('20120330204706');

INSERT INTO schema_migrations (version) VALUES ('20120331175134');

INSERT INTO schema_migrations (version) VALUES ('20120402220056');

INSERT INTO schema_migrations (version) VALUES ('20120404163503');

INSERT INTO schema_migrations (version) VALUES ('20120405013956');

INSERT INTO schema_migrations (version) VALUES ('20120423192718');

INSERT INTO schema_migrations (version) VALUES ('20120424130756');

INSERT INTO schema_migrations (version) VALUES ('20120424183505');

INSERT INTO schema_migrations (version) VALUES ('20120424191516');

INSERT INTO schema_migrations (version) VALUES ('20120424194311');

INSERT INTO schema_migrations (version) VALUES ('20120427165336');

INSERT INTO schema_migrations (version) VALUES ('20120509144947');

INSERT INTO schema_migrations (version) VALUES ('20120517205400');

INSERT INTO schema_migrations (version) VALUES ('20120522184324');

INSERT INTO schema_migrations (version) VALUES ('20120523190907');

INSERT INTO schema_migrations (version) VALUES ('20120523210435');

INSERT INTO schema_migrations (version) VALUES ('20120523212923');

INSERT INTO schema_migrations (version) VALUES ('20120525132155');

INSERT INTO schema_migrations (version) VALUES ('20120528191901');

INSERT INTO schema_migrations (version) VALUES ('20120529190915');

INSERT INTO schema_migrations (version) VALUES ('20120531202725');

INSERT INTO schema_migrations (version) VALUES ('20120531204028');

INSERT INTO schema_migrations (version) VALUES ('20120605204938');

INSERT INTO schema_migrations (version) VALUES ('20120606145910');

INSERT INTO schema_migrations (version) VALUES ('20120606235805');

INSERT INTO schema_migrations (version) VALUES ('20120609125936');

INSERT INTO schema_migrations (version) VALUES ('20120717195403');

INSERT INTO schema_migrations (version) VALUES ('20120913194222');

INSERT INTO schema_migrations (version) VALUES ('20120924065159');

INSERT INTO schema_migrations (version) VALUES ('20120926184516');

INSERT INTO schema_migrations (version) VALUES ('20121003213137');

INSERT INTO schema_migrations (version) VALUES ('20121005151834');

INSERT INTO schema_migrations (version) VALUES ('20121023210315');

INSERT INTO schema_migrations (version) VALUES ('20121107152946');

INSERT INTO schema_migrations (version) VALUES ('20121108200031');

INSERT INTO schema_migrations (version) VALUES ('20121115201514');

INSERT INTO schema_migrations (version) VALUES ('20121203214837');

INSERT INTO schema_migrations (version) VALUES ('20121223145052');

INSERT INTO schema_migrations (version) VALUES ('20121223165958');

INSERT INTO schema_migrations (version) VALUES ('20121224123025');

INSERT INTO schema_migrations (version) VALUES ('20130107135513');

INSERT INTO schema_migrations (version) VALUES ('20130107193956');

INSERT INTO schema_migrations (version) VALUES ('20130109160332');

INSERT INTO schema_migrations (version) VALUES ('20130110204055');

INSERT INTO schema_migrations (version) VALUES ('20130111164215');

INSERT INTO schema_migrations (version) VALUES ('20130119193907');

INSERT INTO schema_migrations (version) VALUES ('20130119202905');

INSERT INTO schema_migrations (version) VALUES ('20130213173322');

INSERT INTO schema_migrations (version) VALUES ('20130222192624');

INSERT INTO schema_migrations (version) VALUES ('20130607153639');

INSERT INTO schema_migrations (version) VALUES ('20130607202118');

INSERT INTO schema_migrations (version) VALUES ('20130612033951');

INSERT INTO schema_migrations (version) VALUES ('20130613201210');

INSERT INTO schema_migrations (version) VALUES ('20130620172556');

INSERT INTO schema_migrations (version) VALUES ('20130628201906');

INSERT INTO schema_migrations (version) VALUES ('20130708145444');

INSERT INTO schema_migrations (version) VALUES ('20130708164710');

INSERT INTO schema_migrations (version) VALUES ('20130708194848');

INSERT INTO schema_migrations (version) VALUES ('20130708222442');

INSERT INTO schema_migrations (version) VALUES ('20130710141952');

INSERT INTO schema_migrations (version) VALUES ('20130710151956');

INSERT INTO schema_migrations (version) VALUES ('20130710152055');

INSERT INTO schema_migrations (version) VALUES ('20130805160836');

INSERT INTO schema_migrations (version) VALUES ('20130812175422');

INSERT INTO schema_migrations (version) VALUES ('20130821201443');

INSERT INTO schema_migrations (version) VALUES ('20131119030333');

INSERT INTO schema_migrations (version) VALUES ('20140111151946');

INSERT INTO schema_migrations (version) VALUES ('20140114193955');

INSERT INTO schema_migrations (version) VALUES ('20140120124850');

INSERT INTO schema_migrations (version) VALUES ('20140128153112');

INSERT INTO schema_migrations (version) VALUES ('20140204165556');

INSERT INTO schema_migrations (version) VALUES ('20140205020709');

INSERT INTO schema_migrations (version) VALUES ('20140207151457');

INSERT INTO schema_migrations (version) VALUES ('20140320213717');

INSERT INTO schema_migrations (version) VALUES ('20140325143531');

INSERT INTO schema_migrations (version) VALUES ('20140618153152');

INSERT INTO schema_migrations (version) VALUES ('20140625153152');

INSERT INTO schema_migrations (version) VALUES ('20140707103152');

INSERT INTO schema_migrations (version) VALUES ('20140707182714');

INSERT INTO schema_migrations (version) VALUES ('20140709113152');

INSERT INTO schema_migrations (version) VALUES ('20140730113153');

INSERT INTO schema_migrations (version) VALUES ('20140801103154');

INSERT INTO schema_migrations (version) VALUES ('20140807133854');

INSERT INTO schema_migrations (version) VALUES ('20140807133855');

INSERT INTO schema_migrations (version) VALUES ('20140807135553');

INSERT INTO schema_migrations (version) VALUES ('20140818154803');

INSERT INTO schema_migrations (version) VALUES ('20140820113022');

INSERT INTO schema_migrations (version) VALUES ('20140820120441');

INSERT INTO schema_migrations (version) VALUES ('20140821112305');

INSERT INTO schema_migrations (version) VALUES ('20140901145600');

INSERT INTO schema_migrations (version) VALUES ('20140901165529');

INSERT INTO schema_migrations (version) VALUES ('20140915141209');

INSERT INTO schema_migrations (version) VALUES ('20140926145155');

INSERT INTO schema_migrations (version) VALUES ('20140930154815');

INSERT INTO schema_migrations (version) VALUES ('20141006182418');

INSERT INTO schema_migrations (version) VALUES ('20141031142740');

INSERT INTO schema_migrations (version) VALUES ('20141111222139');

INSERT INTO schema_migrations (version) VALUES ('20141119012857');

INSERT INTO schema_migrations (version) VALUES ('20141201142757');

INSERT INTO schema_migrations (version) VALUES ('20141203174739');

INSERT INTO schema_migrations (version) VALUES ('20141215161039');

INSERT INTO schema_migrations (version) VALUES ('20141216133726');

INSERT INTO schema_migrations (version) VALUES ('20141226170459');

INSERT INTO schema_migrations (version) VALUES ('20141230003854');

INSERT INTO schema_migrations (version) VALUES ('20150106174739');

INSERT INTO schema_migrations (version) VALUES ('20150123123429');

INSERT INTO schema_migrations (version) VALUES ('20150127011605');

INSERT INTO schema_migrations (version) VALUES ('20150127184809');

INSERT INTO schema_migrations (version) VALUES ('20150130162239');

INSERT INTO schema_migrations (version) VALUES ('20150202221959');

INSERT INTO schema_migrations (version) VALUES ('20150212133202');

INSERT INTO schema_migrations (version) VALUES ('20150220141300');

INSERT INTO schema_migrations (version) VALUES ('20150221153949');

INSERT INTO schema_migrations (version) VALUES ('20150225181123');

INSERT INTO schema_migrations (version) VALUES ('20150226131119');

INSERT INTO schema_migrations (version) VALUES ('20150228143706');

INSERT INTO schema_migrations (version) VALUES ('20150302140850');

INSERT INTO schema_migrations (version) VALUES ('20150309205439');

INSERT INTO schema_migrations (version) VALUES ('20150327115920');

INSERT INTO schema_migrations (version) VALUES ('20150410120313');

INSERT INTO schema_migrations (version) VALUES ('20150416191837');

INSERT INTO schema_migrations (version) VALUES ('20150423195307');

INSERT INTO schema_migrations (version) VALUES ('20150501024703');

INSERT INTO schema_migrations (version) VALUES ('20150514012021');

INSERT INTO schema_migrations (version) VALUES ('20150528170855');

INSERT INTO schema_migrations (version) VALUES ('20150605194836');

INSERT INTO schema_migrations (version) VALUES ('20150714135841');

INSERT INTO schema_migrations (version) VALUES ('20150804155832');

INSERT INTO schema_migrations (version) VALUES ('20150807145306');

INSERT INTO schema_migrations (version) VALUES ('20150814142759');

INSERT INTO schema_migrations (version) VALUES ('20150826193355');

INSERT INTO schema_migrations (version) VALUES ('20150901153709');

INSERT INTO schema_migrations (version) VALUES ('20150902190501');

INSERT INTO schema_migrations (version) VALUES ('20150915141504');

INSERT INTO schema_migrations (version) VALUES ('20150915181704');

INSERT INTO schema_migrations (version) VALUES ('20151019190942');

INSERT INTO schema_migrations (version) VALUES ('20151116162403');

INSERT INTO schema_migrations (version) VALUES ('20151210152844');

INSERT INTO schema_migrations (version) VALUES ('20151221004231');

INSERT INTO schema_migrations (version) VALUES ('20151221154339');

INSERT INTO schema_migrations (version) VALUES ('20160202105600');

INSERT INTO schema_migrations (version) VALUES ('20160202192709');

INSERT INTO schema_migrations (version) VALUES ('20160204190034');

INSERT INTO schema_migrations (version) VALUES ('20160204190056');

INSERT INTO schema_migrations (version) VALUES ('20160204190101');

INSERT INTO schema_migrations (version) VALUES ('20160204190107');

INSERT INTO schema_migrations (version) VALUES ('20160204190113');

INSERT INTO schema_migrations (version) VALUES ('20160210153932');

INSERT INTO schema_migrations (version) VALUES ('20160210153937');

INSERT INTO schema_migrations (version) VALUES ('20160210153943');

INSERT INTO schema_migrations (version) VALUES ('20160210153951');

INSERT INTO schema_migrations (version) VALUES ('20160211113711');

INSERT INTO schema_migrations (version) VALUES ('20160215185431');

INSERT INTO schema_migrations (version) VALUES ('20160217173440');

INSERT INTO schema_migrations (version) VALUES ('20160302160145');

INSERT INTO schema_migrations (version) VALUES ('20160329200413');

INSERT INTO schema_migrations (version) VALUES ('20160401173537');

INSERT INTO schema_migrations (version) VALUES ('20160413150136');

INSERT INTO schema_migrations (version) VALUES ('20160419135520');

INSERT INTO schema_migrations (version) VALUES ('20160427165242');

INSERT INTO schema_migrations (version) VALUES ('20160428125403');

INSERT INTO schema_migrations (version) VALUES ('20160429175451');

INSERT INTO schema_migrations (version) VALUES ('20160513173621');

INSERT INTO schema_migrations (version) VALUES ('20160517160526');

INSERT INTO schema_migrations (version) VALUES ('20160517161104');

INSERT INTO schema_migrations (version) VALUES ('20160517174101');

INSERT INTO schema_migrations (version) VALUES ('20160518122049');

INSERT INTO schema_migrations (version) VALUES ('20160518122605');

INSERT INTO schema_migrations (version) VALUES ('20160518143500');

INSERT INTO schema_migrations (version) VALUES ('20160523162335');

INSERT INTO schema_migrations (version) VALUES ('20160523203413');

INSERT INTO schema_migrations (version) VALUES ('20160602005533');

INSERT INTO schema_migrations (version) VALUES ('20160603231000');

INSERT INTO schema_migrations (version) VALUES ('20160606160232');

INSERT INTO schema_migrations (version) VALUES ('20160610044352');

