--
-- PostgreSQL database dump
--

-- Dumped from database version 10.1
-- Dumped by pg_dump version 10.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account_list_coaches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_list_coaches (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    coach_id uuid,
    account_list_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_list_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_list_entries (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_list_id uuid,
    designation_account_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_list_invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_list_invites (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_list_id uuid,
    invited_by_user_id uuid NOT NULL,
    code character varying NOT NULL,
    recipient_email character varying NOT NULL,
    accepted_by_user_id uuid,
    accepted_at timestamp without time zone,
    cancelled_by_user_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    invite_user_as character varying DEFAULT 'user'::character varying
);


--
-- Name: account_list_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_list_users (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    user_id uuid,
    account_list_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE account_lists (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying,
    creator_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    settings text,
    active_mpd_start_at date,
    active_mpd_finish_at date,
    active_mpd_monthly_goal numeric,
    primary_appeal_id uuid
);


--
-- Name: activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activities (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_list_id uuid,
    starred boolean DEFAULT false NOT NULL,
    location character varying,
    subject character varying(2000),
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    completed boolean DEFAULT false NOT NULL,
    activity_comments_count integer DEFAULT 0,
    activity_type character varying,
    result character varying,
    completed_at timestamp without time zone,
    notification_id uuid,
    remote_id character varying,
    source character varying,
    next_action character varying,
    no_date boolean DEFAULT false,
    notification_type integer,
    notification_time_before integer,
    notification_time_unit integer,
    notification_scheduled boolean
);


--
-- Name: activity_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_comments (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    activity_id uuid,
    person_id uuid,
    body text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: activity_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE activity_contacts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    activity_id uuid,
    contact_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE addresses (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    addressable_id uuid,
    street text,
    city character varying,
    state character varying,
    country character varying,
    postal_code character varying,
    location character varying,
    start_date date,
    end_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    primary_mailing_address boolean DEFAULT false,
    addressable_type character varying,
    remote_id character varying,
    seasonal boolean DEFAULT false,
    master_address_id uuid NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    region character varying,
    metro_area character varying,
    historic boolean DEFAULT false,
    source character varying DEFAULT 'MPDX'::character varying,
    source_donor_account_id uuid,
    valid_values boolean DEFAULT false
);


--
-- Name: admin_impersonation_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE admin_impersonation_logs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    reason text NOT NULL,
    impersonator_id uuid NOT NULL,
    impersonated_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: admin_reset_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE admin_reset_logs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    admin_resetting_id uuid,
    resetted_user_id uuid,
    reason character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    completed_at timestamp without time zone
);


--
-- Name: appeal_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE appeal_contacts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    appeal_id uuid,
    contact_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: appeal_excluded_appeal_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE appeal_excluded_appeal_contacts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    appeal_id uuid,
    contact_id uuid,
    reasons text[],
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: appeals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE appeals (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying,
    account_list_id uuid,
    amount numeric(19,2),
    description text,
    end_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tnt_id integer,
    active boolean DEFAULT true,
    monthly_amount numeric
);


--
-- Name: background_batch_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE background_batch_requests (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    background_batch_id uuid,
    path character varying,
    request_params character varying,
    request_body character varying,
    request_headers character varying,
    request_method character varying DEFAULT 'GET'::character varying,
    response_headers character varying,
    response_body character varying,
    response_status character varying,
    status integer DEFAULT 0,
    default_account_list boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: background_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE background_batches (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    batch_id character varying,
    user_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: balances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE balances (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    balance numeric,
    resource_id uuid,
    resource_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE companies (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    street text,
    city character varying,
    state character varying,
    postal_code character varying,
    country character varying,
    phone_number character varying,
    master_company_id uuid
);


--
-- Name: company_partnerships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE company_partnerships (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_list_id uuid,
    company_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: company_positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE company_positions (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid NOT NULL,
    company_id uuid NOT NULL,
    start_date date,
    end_date date,
    "position" character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contact_donor_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contact_donor_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    contact_id uuid,
    donor_account_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contact_notes_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contact_notes_logs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    contact_id uuid,
    recorded_on date,
    notes text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contact_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contact_people (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    contact_id uuid,
    person_id uuid,
    "primary" boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contact_referrals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contact_referrals (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    referred_by_id uuid,
    referred_to_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contacts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying,
    account_list_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    pledge_amount numeric(19,2),
    status character varying,
    total_donations numeric(19,2),
    last_donation_date date,
    first_donation_date date,
    notes text,
    notes_saved_at timestamp without time zone,
    full_name character varying,
    greeting character varying,
    website character varying(1000),
    pledge_frequency numeric,
    pledge_start_date date,
    next_ask date,
    likely_to_give character varying,
    church_name text,
    send_newsletter character varying,
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
    deprecated_not_duplicated_with character varying(2000),
    uncompleted_tasks_count integer DEFAULT 0 NOT NULL,
    prayer_letters_id character varying,
    timezone character varying,
    envelope_greeting character varying,
    no_appeals boolean,
    pls_id character varying,
    prayer_letters_params text,
    pledge_currency_code character varying(4),
    pledge_currency character varying(4),
    locale character varying,
    late_at date,
    status_valid boolean,
    suggested_changes text,
    is_organization boolean DEFAULT false,
    no_gift_aid boolean,
    estimated_annual_pledge_amount numeric(19,2),
    next_ask_amount numeric(19,2),
    status_confirmed_at timestamp without time zone
);


--
-- Name: currency_aliases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE currency_aliases (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    alias_code character varying NOT NULL,
    rate_api_code character varying NOT NULL,
    ratio numeric NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: currency_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE currency_rates (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    exchanged_on date NOT NULL,
    code character varying NOT NULL,
    rate numeric(20,10) NOT NULL,
    source character varying NOT NULL
);


--
-- Name: designation_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE designation_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    designation_number character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    organization_id uuid,
    balance numeric(19,2),
    balance_updated_at timestamp without time zone,
    name character varying,
    staff_account_id character varying,
    chartfield character varying,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: designation_profile_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE designation_profile_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    designation_profile_id uuid,
    designation_account_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: designation_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE designation_profiles (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    remote_id character varying,
    user_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    code character varying,
    balance numeric(19,2),
    balance_updated_at timestamp without time zone,
    account_list_id uuid
);


--
-- Name: donation_amount_recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE donation_amount_recommendations (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    started_at timestamp without time zone,
    suggested_pledge_amount numeric,
    suggested_special_amount numeric,
    ask_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    designation_account_id uuid,
    donor_account_id uuid
);


--
-- Name: donations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE donations (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    remote_id character varying,
    donor_account_id uuid,
    designation_account_id uuid,
    motivation character varying,
    payment_method character varying,
    tendered_currency character varying,
    tendered_amount numeric(19,2),
    currency character varying,
    amount numeric(19,2),
    memo text,
    donation_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    payment_type character varying,
    channel character varying,
    appeal_id uuid,
    appeal_amount numeric(19,2),
    tnt_id character varying
);


--
-- Name: donor_account_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE donor_account_people (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    donor_account_id uuid,
    person_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: donor_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE donor_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    organization_id uuid,
    account_number character varying,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    master_company_id uuid,
    total_donations numeric(19,2),
    last_donation_date date,
    first_donation_date date,
    donor_type character varying(20)
);


--
-- Name: duplicate_record_pairs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE duplicate_record_pairs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_list_id uuid NOT NULL,
    record_one_id uuid NOT NULL,
    record_one_type character varying NOT NULL,
    record_two_id uuid NOT NULL,
    record_two_type character varying NOT NULL,
    reason character varying NOT NULL,
    ignore boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: email_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE email_addresses (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid,
    email character varying NOT NULL,
    "primary" boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_id character varying,
    location character varying(50),
    historic boolean DEFAULT false,
    deleted boolean DEFAULT false,
    valid_values boolean DEFAULT true,
    source character varying DEFAULT 'MPDX'::character varying,
    checked_for_google_plus_account boolean DEFAULT false NOT NULL,
    global_registry_id uuid
);


--
-- Name: export_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE export_logs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    type character varying,
    params text,
    user_id uuid,
    export_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: family_relationships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE family_relationships (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid,
    related_person_id uuid,
    relationship character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: google_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE google_contacts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    remote_id character varying,
    person_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    picture_etag character varying,
    picture_id uuid,
    google_account_id uuid,
    last_synced timestamp without time zone,
    last_etag character varying,
    last_data text,
    contact_id uuid
);


--
-- Name: google_email_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE google_email_activities (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    google_email_id uuid,
    activity_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: google_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE google_emails (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    google_account_id uuid,
    google_email_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: google_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE google_events (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    activity_id uuid,
    google_integration_id uuid,
    google_event_id character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    calendar_id character varying
);


--
-- Name: google_integrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE google_integrations (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_list_id uuid,
    google_account_id uuid,
    calendar_integration boolean DEFAULT false NOT NULL,
    calendar_integrations text,
    calendar_id character varying,
    calendar_name character varying,
    email_integration boolean DEFAULT false NOT NULL,
    contacts_integration boolean DEFAULT false NOT NULL,
    contacts_last_synced timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    email_blacklist text
);


--
-- Name: google_plus_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE google_plus_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id character varying,
    profile_picture_link character varying,
    email_address_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: help_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE help_requests (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying,
    browser text,
    problem text,
    email character varying,
    file character varying,
    user_id uuid,
    account_list_id uuid,
    session text,
    user_preferences text,
    account_list_settings text,
    request_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE imports (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_list_id uuid,
    source character varying,
    file character varying,
    importing boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tags text,
    override boolean DEFAULT false NOT NULL,
    user_id uuid,
    source_account_id integer,
    import_by_group boolean DEFAULT false,
    groups text,
    group_tags text,
    in_preview boolean DEFAULT false NOT NULL,
    file_headers text,
    file_constants text,
    file_headers_mappings text,
    file_constants_mappings text,
    file_row_samples text,
    file_row_failures text,
    queued_for_import_at timestamp without time zone,
    import_completed_at timestamp without time zone,
    import_started_at timestamp without time zone,
    error text
);


--
-- Name: mail_chimp_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mail_chimp_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    api_key character varying,
    active boolean DEFAULT false,
    status_grouping_id character varying,
    primary_list_id character varying,
    account_list_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    webhook_token character varying,
    auto_log_campaigns boolean DEFAULT false NOT NULL,
    importing boolean DEFAULT false NOT NULL,
    status_interest_ids text,
    tags_grouping_id character varying,
    tags_interest_ids text,
    sync_all_active_contacts boolean,
    prayer_letter_last_sent timestamp without time zone,
    tags_details text,
    statuses_details text
);


--
-- Name: mail_chimp_appeal_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mail_chimp_appeal_lists (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    mail_chimp_account_id uuid NOT NULL,
    appeal_list_id character varying NOT NULL,
    appeal_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: mail_chimp_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mail_chimp_members (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    mail_chimp_account_id uuid NOT NULL,
    list_id character varying NOT NULL,
    email character varying NOT NULL,
    status character varying,
    greeting character varying,
    first_name character varying,
    last_name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    contact_locale character varying,
    tags character varying[]
);


--
-- Name: master_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_addresses (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    street text,
    city character varying,
    state character varying,
    country character varying,
    postal_code character varying,
    verified boolean DEFAULT false NOT NULL,
    smarty_response text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    latitude character varying,
    longitude character varying,
    last_geocoded_at timestamp without time zone
);


--
-- Name: master_companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_companies (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: master_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_people (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: master_person_donor_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_person_donor_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    master_person_id uuid,
    donor_account_id uuid,
    "primary" boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: master_person_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE master_person_sources (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    master_person_id uuid,
    organization_id uuid,
    remote_id character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE messages (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    from_id uuid,
    to_id uuid,
    subject character varying,
    body text,
    sent_at timestamp without time zone,
    source character varying,
    remote_id character varying,
    contact_id uuid,
    account_list_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: name_male_ratios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE name_male_ratios (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    male_ratio double precision NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: nicknames; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE nicknames (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    nickname character varying NOT NULL,
    source character varying,
    num_merges integer DEFAULT 0 NOT NULL,
    num_not_duplicates integer DEFAULT 0 NOT NULL,
    num_times_offered integer DEFAULT 0 NOT NULL,
    suggest_duplicates boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE notification_preferences (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    notification_type_id uuid,
    account_list_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id uuid,
    email boolean DEFAULT true,
    task boolean DEFAULT true
);


--
-- Name: notification_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE notification_types (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    type character varying,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    description_for_email text
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE notifications (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    contact_id uuid,
    notification_type_id uuid,
    event_date timestamp without time zone,
    cleared boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    donation_id uuid
);


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE organizations (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying,
    query_ini_url character varying,
    iso3166 character varying,
    minimum_gift_date character varying,
    logo character varying,
    code character varying,
    query_authentication boolean,
    account_help_url character varying,
    abbreviation character varying,
    org_help_email character varying,
    org_help_url character varying,
    org_help_url_description character varying,
    org_help_other text,
    request_profile_url character varying,
    staff_portal_url character varying,
    default_currency_code character varying,
    allow_passive_auth boolean,
    account_balance_url character varying,
    account_balance_params character varying,
    donations_url character varying,
    donations_params character varying,
    addresses_url character varying,
    addresses_params character varying,
    addresses_by_personids_url character varying,
    addresses_by_personids_params character varying,
    profiles_url character varying,
    profiles_params character varying,
    redirect_query_ini character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    api_class character varying,
    country character varying,
    uses_key_auth boolean DEFAULT false,
    locale character varying DEFAULT 'en'::character varying NOT NULL,
    gift_aid_percentage numeric,
    oauth_url character varying,
    oauth_get_challenge_start_num_url character varying,
    oauth_get_challenge_start_num_params character varying,
    oauth_get_challenge_start_num_oauth character varying,
    oauth_convert_to_token_url character varying,
    oauth_convert_to_token_params character varying,
    oauth_convert_to_token_oauth character varying,
    oauth_get_token_info_url character varying,
    oauth_get_token_info_params character varying,
    oauth_get_token_info_oauth character varying,
    account_balance_oauth character varying,
    donations_oauth character varying,
    addresses_oauth character varying,
    addresses_by_personids_oauth character varying,
    profiles_oauth character varying,
    organization_type character varying DEFAULT 'Non-Cru'::character varying
);


--
-- Name: partner_status_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE partner_status_logs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    contact_id uuid NOT NULL,
    recorded_on date NOT NULL,
    status character varying,
    pledge_amount numeric,
    pledge_frequency numeric,
    pledge_received boolean,
    pledge_start_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE people (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    first_name character varying NOT NULL,
    legal_first_name character varying,
    last_name character varying,
    birthday_month integer,
    birthday_year integer,
    birthday_day integer,
    anniversary_month integer,
    anniversary_year integer,
    anniversary_day integer,
    title character varying,
    suffix character varying,
    gender character varying,
    marital_status character varying,
    preferences text,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    master_person_id uuid NOT NULL,
    middle_name character varying,
    access_token character varying(32),
    profession text,
    deceased boolean DEFAULT false NOT NULL,
    subscribed_to_updates boolean,
    optout_enewsletter boolean DEFAULT false,
    occupation character varying,
    employer character varying,
    deprecated_not_duplicated_with character varying(2000),
    global_registry_id uuid,
    global_registry_mdm_id uuid
);


--
-- Name: person_facebook_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE person_facebook_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid NOT NULL,
    remote_id bigint,
    token character varying,
    token_expires_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    valid_token boolean DEFAULT false,
    first_name character varying,
    last_name character varying,
    authenticated boolean DEFAULT false NOT NULL,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone,
    username character varying
);


--
-- Name: person_google_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE person_google_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    remote_id text,
    person_id uuid,
    token character varying,
    refresh_token character varying,
    expires_at timestamp without time zone,
    valid_token boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    email character varying NOT NULL,
    authenticated boolean DEFAULT false NOT NULL,
    "primary" boolean DEFAULT false,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone,
    last_email_sync timestamp without time zone,
    notified_failure boolean
);


--
-- Name: person_key_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE person_key_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid,
    remote_id character varying,
    first_name character varying,
    last_name character varying,
    email character varying,
    authenticated boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "primary" boolean DEFAULT false,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone
);


--
-- Name: person_linkedin_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE person_linkedin_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid NOT NULL,
    remote_id character varying,
    token character varying,
    secret character varying,
    token_expires_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    valid_token boolean DEFAULT false,
    first_name character varying,
    last_name character varying,
    authenticated boolean DEFAULT false NOT NULL,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone,
    public_url text
);


--
-- Name: person_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE person_options (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    key character varying NOT NULL,
    value character varying,
    user_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: person_organization_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE person_organization_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid,
    organization_id uuid,
    username character varying,
    password character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_id character varying,
    authenticated boolean DEFAULT false NOT NULL,
    valid_credentials boolean DEFAULT false NOT NULL,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone,
    token character varying,
    locked_at timestamp without time zone,
    disable_downloads boolean DEFAULT false NOT NULL,
    last_download_attempt_at timestamp without time zone
);


--
-- Name: person_relay_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE person_relay_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid,
    relay_remote_id character varying,
    first_name character varying,
    last_name character varying,
    email character varying,
    designation character varying,
    employee_id character varying,
    username character varying,
    authenticated boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    "primary" boolean DEFAULT false,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone,
    remote_id character varying NOT NULL
);


--
-- Name: person_twitter_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE person_twitter_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid NOT NULL,
    remote_id bigint,
    screen_name character varying,
    token character varying,
    secret character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    valid_token boolean DEFAULT false,
    authenticated boolean DEFAULT false NOT NULL,
    "primary" boolean DEFAULT false,
    downloading boolean DEFAULT false NOT NULL,
    last_download timestamp without time zone
);


--
-- Name: person_websites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE person_websites (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid,
    url text,
    "primary" boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: phone_numbers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE phone_numbers (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    person_id uuid,
    number character varying,
    country_code character varying,
    location character varying,
    "primary" boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remote_id character varying,
    historic boolean DEFAULT false,
    valid_values boolean DEFAULT true,
    source character varying DEFAULT 'MPDX'::character varying,
    global_registry_id uuid
);


--
-- Name: pictures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pictures (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    picture_of_id uuid,
    picture_of_type character varying,
    image character varying,
    "primary" boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: pledge_donations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pledge_donations (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    pledge_id uuid,
    donation_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: pledges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pledges (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    amount numeric,
    expected_date date,
    account_list_id uuid,
    contact_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    amount_currency character varying,
    appeal_id uuid,
    status character varying DEFAULT 'not_received'::character varying
);


--
-- Name: pls_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pls_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_list_id uuid,
    oauth2_token character varying,
    valid_token boolean DEFAULT true,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: prayer_letters_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE prayer_letters_accounts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    token character varying,
    secret character varying,
    valid_token boolean DEFAULT true,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_list_id uuid,
    oauth2_token character varying
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE taggings (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    tag_id uuid,
    taggable_id uuid,
    taggable_type character varying,
    tagger_id integer,
    tagger_type character varying,
    context character varying(128),
    created_at timestamp without time zone NOT NULL
);


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tags (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying,
    taggings_count integer DEFAULT 0
);


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions (
    id integer NOT NULL,
    item_type character varying NOT NULL,
    item_id integer NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    related_object_type character varying,
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
-- Name: wv_donation_amt_recommendation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE wv_donation_amt_recommendation (
    organization_id integer,
    donor_number character varying,
    designation_number character varying,
    previous_amount numeric,
    amount numeric,
    started_at timestamp without time zone,
    gift_min numeric,
    gift_max numeric,
    income_min numeric,
    income_max numeric,
    suggested_pledge_amount numeric,
    ask_at timestamp without time zone,
    zip_code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: account_list_coaches account_list_coaches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_list_coaches
    ADD CONSTRAINT account_list_coaches_pkey PRIMARY KEY (id);


--
-- Name: account_list_entries account_list_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_list_entries
    ADD CONSTRAINT account_list_entries_pkey PRIMARY KEY (id);


--
-- Name: account_list_invites account_list_invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_list_invites
    ADD CONSTRAINT account_list_invites_pkey PRIMARY KEY (id);


--
-- Name: account_list_users account_list_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_list_users
    ADD CONSTRAINT account_list_users_pkey PRIMARY KEY (id);


--
-- Name: account_lists account_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY account_lists
    ADD CONSTRAINT account_lists_pkey PRIMARY KEY (id);


--
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: activity_comments activity_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_comments
    ADD CONSTRAINT activity_comments_pkey PRIMARY KEY (id);


--
-- Name: activity_contacts activity_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY activity_contacts
    ADD CONSTRAINT activity_contacts_pkey PRIMARY KEY (id);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: admin_impersonation_logs admin_impersonation_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY admin_impersonation_logs
    ADD CONSTRAINT admin_impersonation_logs_pkey PRIMARY KEY (id);


--
-- Name: admin_reset_logs admin_reset_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY admin_reset_logs
    ADD CONSTRAINT admin_reset_logs_pkey PRIMARY KEY (id);


--
-- Name: appeal_contacts appeal_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appeal_contacts
    ADD CONSTRAINT appeal_contacts_pkey PRIMARY KEY (id);


--
-- Name: appeal_excluded_appeal_contacts appeal_excluded_appeal_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appeal_excluded_appeal_contacts
    ADD CONSTRAINT appeal_excluded_appeal_contacts_pkey PRIMARY KEY (id);


--
-- Name: appeals appeals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appeals
    ADD CONSTRAINT appeals_pkey PRIMARY KEY (id);


--
-- Name: background_batch_requests background_batch_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY background_batch_requests
    ADD CONSTRAINT background_batch_requests_pkey PRIMARY KEY (id);


--
-- Name: background_batches background_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY background_batches
    ADD CONSTRAINT background_batches_pkey PRIMARY KEY (id);


--
-- Name: balances balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY balances
    ADD CONSTRAINT balances_pkey PRIMARY KEY (id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: company_partnerships company_partnerships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY company_partnerships
    ADD CONSTRAINT company_partnerships_pkey PRIMARY KEY (id);


--
-- Name: company_positions company_positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY company_positions
    ADD CONSTRAINT company_positions_pkey PRIMARY KEY (id);


--
-- Name: contact_donor_accounts contact_donor_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_donor_accounts
    ADD CONSTRAINT contact_donor_accounts_pkey PRIMARY KEY (id);


--
-- Name: contact_notes_logs contact_notes_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_notes_logs
    ADD CONSTRAINT contact_notes_logs_pkey PRIMARY KEY (id);


--
-- Name: contact_people contact_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_people
    ADD CONSTRAINT contact_people_pkey PRIMARY KEY (id);


--
-- Name: contact_referrals contact_referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_referrals
    ADD CONSTRAINT contact_referrals_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: currency_aliases currency_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY currency_aliases
    ADD CONSTRAINT currency_aliases_pkey PRIMARY KEY (id);


--
-- Name: currency_rates currency_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY currency_rates
    ADD CONSTRAINT currency_rates_pkey PRIMARY KEY (id);


--
-- Name: designation_accounts designation_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY designation_accounts
    ADD CONSTRAINT designation_accounts_pkey PRIMARY KEY (id);


--
-- Name: designation_profile_accounts designation_profile_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY designation_profile_accounts
    ADD CONSTRAINT designation_profile_accounts_pkey PRIMARY KEY (id);


--
-- Name: designation_profiles designation_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY designation_profiles
    ADD CONSTRAINT designation_profiles_pkey PRIMARY KEY (id);


--
-- Name: donation_amount_recommendations donation_amount_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donation_amount_recommendations
    ADD CONSTRAINT donation_amount_recommendations_pkey PRIMARY KEY (id);


--
-- Name: donations donations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donations
    ADD CONSTRAINT donations_pkey PRIMARY KEY (id);


--
-- Name: donor_account_people donor_account_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donor_account_people
    ADD CONSTRAINT donor_account_people_pkey PRIMARY KEY (id);


--
-- Name: donor_accounts donor_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donor_accounts
    ADD CONSTRAINT donor_accounts_pkey PRIMARY KEY (id);


--
-- Name: duplicate_record_pairs duplicate_record_pairs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY duplicate_record_pairs
    ADD CONSTRAINT duplicate_record_pairs_pkey PRIMARY KEY (id);


--
-- Name: email_addresses email_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_addresses
    ADD CONSTRAINT email_addresses_pkey PRIMARY KEY (id);


--
-- Name: export_logs export_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY export_logs
    ADD CONSTRAINT export_logs_pkey PRIMARY KEY (id);


--
-- Name: family_relationships family_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY family_relationships
    ADD CONSTRAINT family_relationships_pkey PRIMARY KEY (id);


--
-- Name: google_contacts google_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_contacts
    ADD CONSTRAINT google_contacts_pkey PRIMARY KEY (id);


--
-- Name: google_email_activities google_email_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_email_activities
    ADD CONSTRAINT google_email_activities_pkey PRIMARY KEY (id);


--
-- Name: google_emails google_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_emails
    ADD CONSTRAINT google_emails_pkey PRIMARY KEY (id);


--
-- Name: google_events google_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_events
    ADD CONSTRAINT google_events_pkey PRIMARY KEY (id);


--
-- Name: google_integrations google_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_integrations
    ADD CONSTRAINT google_integrations_pkey PRIMARY KEY (id);


--
-- Name: google_plus_accounts google_plus_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY google_plus_accounts
    ADD CONSTRAINT google_plus_accounts_pkey PRIMARY KEY (id);


--
-- Name: help_requests help_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY help_requests
    ADD CONSTRAINT help_requests_pkey PRIMARY KEY (id);


--
-- Name: imports imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: mail_chimp_accounts mail_chimp_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_chimp_accounts
    ADD CONSTRAINT mail_chimp_accounts_pkey PRIMARY KEY (id);


--
-- Name: mail_chimp_appeal_lists mail_chimp_appeal_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_chimp_appeal_lists
    ADD CONSTRAINT mail_chimp_appeal_lists_pkey PRIMARY KEY (id);


--
-- Name: mail_chimp_members mail_chimp_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mail_chimp_members
    ADD CONSTRAINT mail_chimp_members_pkey PRIMARY KEY (id);


--
-- Name: master_addresses master_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_addresses
    ADD CONSTRAINT master_addresses_pkey PRIMARY KEY (id);


--
-- Name: master_companies master_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_companies
    ADD CONSTRAINT master_companies_pkey PRIMARY KEY (id);


--
-- Name: master_people master_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_people
    ADD CONSTRAINT master_people_pkey PRIMARY KEY (id);


--
-- Name: master_person_donor_accounts master_person_donor_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_person_donor_accounts
    ADD CONSTRAINT master_person_donor_accounts_pkey PRIMARY KEY (id);


--
-- Name: master_person_sources master_person_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_person_sources
    ADD CONSTRAINT master_person_sources_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: name_male_ratios name_male_ratios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY name_male_ratios
    ADD CONSTRAINT name_male_ratios_pkey PRIMARY KEY (id);


--
-- Name: nicknames nicknames_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY nicknames
    ADD CONSTRAINT nicknames_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: notification_types notification_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_types
    ADD CONSTRAINT notification_types_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: partner_status_logs partner_status_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY partner_status_logs
    ADD CONSTRAINT partner_status_logs_pkey PRIMARY KEY (id);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: person_facebook_accounts person_facebook_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_facebook_accounts
    ADD CONSTRAINT person_facebook_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_google_accounts person_google_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_google_accounts
    ADD CONSTRAINT person_google_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_key_accounts person_key_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_key_accounts
    ADD CONSTRAINT person_key_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_linkedin_accounts person_linkedin_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_linkedin_accounts
    ADD CONSTRAINT person_linkedin_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_options person_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_options
    ADD CONSTRAINT person_options_pkey PRIMARY KEY (id);


--
-- Name: person_organization_accounts person_organization_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_organization_accounts
    ADD CONSTRAINT person_organization_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_relay_accounts person_relay_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_relay_accounts
    ADD CONSTRAINT person_relay_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_twitter_accounts person_twitter_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_twitter_accounts
    ADD CONSTRAINT person_twitter_accounts_pkey PRIMARY KEY (id);


--
-- Name: person_websites person_websites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY person_websites
    ADD CONSTRAINT person_websites_pkey PRIMARY KEY (id);


--
-- Name: phone_numbers phone_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phone_numbers
    ADD CONSTRAINT phone_numbers_pkey PRIMARY KEY (id);


--
-- Name: pictures pictures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pictures
    ADD CONSTRAINT pictures_pkey PRIMARY KEY (id);


--
-- Name: pledge_donations pledge_donations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pledge_donations
    ADD CONSTRAINT pledge_donations_pkey PRIMARY KEY (id);


--
-- Name: pledges pledges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pledges
    ADD CONSTRAINT pledges_pkey PRIMARY KEY (id);


--
-- Name: pls_accounts pls_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pls_accounts
    ADD CONSTRAINT pls_accounts_pkey PRIMARY KEY (id);


--
-- Name: prayer_letters_accounts prayer_letters_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY prayer_letters_accounts
    ADD CONSTRAINT prayer_letters_accounts_pkey PRIMARY KEY (id);


--
-- Name: taggings taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: INDEX_TAGGINGS_ON_TAGGABLE_ID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "INDEX_TAGGINGS_ON_TAGGABLE_ID" ON taggings USING btree (taggable_id);


--
-- Name: activities_on_list_id_completed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activities_on_list_id_completed ON activities USING btree (account_list_id, completed);


--
-- Name: all_fields; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX all_fields ON master_addresses USING btree (street, city, state, country, postal_code);


--
-- Name: designation_p_to_a; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX designation_p_to_a ON designation_profile_accounts USING btree (designation_profile_id, designation_account_id);


--
-- Name: index_account_list_coaches_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_list_coaches_on_account_list_id ON account_list_coaches USING btree (account_list_id);


--
-- Name: index_account_list_coaches_on_coach_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_list_coaches_on_coach_id ON account_list_coaches USING btree (coach_id);


--
-- Name: index_account_list_coaches_on_coach_id_and_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_list_coaches_on_coach_id_and_account_list_id ON account_list_coaches USING btree (coach_id, account_list_id);


--
-- Name: index_account_list_entries_on_designation_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_list_entries_on_designation_account_id ON account_list_entries USING btree (designation_account_id);


--
-- Name: index_account_list_users_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_list_users_on_account_list_id ON account_list_users USING btree (account_list_id);


--
-- Name: index_account_list_users_on_user_id_and_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_list_users_on_user_id_and_account_list_id ON account_list_users USING btree (user_id, account_list_id);


--
-- Name: index_account_lists_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_lists_on_creator_id ON account_lists USING btree (creator_id);


--
-- Name: index_activities_on_activity_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_activity_type ON activities USING btree (activity_type);


--
-- Name: index_activities_on_completed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_completed ON activities USING btree (completed);


--
-- Name: index_activities_on_completed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_completed_at ON activities USING btree (completed_at);


--
-- Name: index_activities_on_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_notification_id ON activities USING btree (notification_id);


--
-- Name: index_activities_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_remote_id ON activities USING btree (remote_id);


--
-- Name: index_activities_on_start_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activities_on_start_at ON activities USING btree (start_at);


--
-- Name: index_activity_comments_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_comments_on_activity_id ON activity_comments USING btree (activity_id);


--
-- Name: index_activity_comments_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_comments_on_person_id ON activity_comments USING btree (person_id);


--
-- Name: index_activity_contacts_on_activity_id_and_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_contacts_on_activity_id_and_contact_id ON activity_contacts USING btree (activity_id, contact_id);


--
-- Name: index_activity_contacts_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_contacts_on_contact_id ON activity_contacts USING btree (contact_id);


--
-- Name: index_activity_contacts_on_contact_id_and_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_activity_contacts_on_contact_id_and_activity_id ON activity_contacts USING btree (contact_id, activity_id);


--
-- Name: index_addresses_on_addressable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_addressable_id ON addresses USING btree (addressable_id);


--
-- Name: index_addresses_on_lower_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_lower_city ON addresses USING btree (lower((city)::text));


--
-- Name: index_addresses_on_lower_street; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_lower_street ON addresses USING btree (lower(street));


--
-- Name: index_addresses_on_master_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_master_address_id ON addresses USING btree (master_address_id);


--
-- Name: index_addresses_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_remote_id ON addresses USING btree (remote_id);


--
-- Name: index_addresses_on_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_source ON addresses USING btree (source);


--
-- Name: index_addresses_on_valid_values; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_valid_values ON addresses USING btree (valid_values);


--
-- Name: index_appeal_contacts_on_appeal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appeal_contacts_on_appeal_id ON appeal_contacts USING btree (appeal_id);


--
-- Name: index_appeal_contacts_on_appeal_id_and_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_appeal_contacts_on_appeal_id_and_contact_id ON appeal_contacts USING btree (appeal_id, contact_id);


--
-- Name: index_appeal_contacts_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appeal_contacts_on_contact_id ON appeal_contacts USING btree (contact_id);


--
-- Name: index_appeals_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appeals_on_account_list_id ON appeals USING btree (account_list_id);


--
-- Name: index_background_batch_requests_on_background_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_background_batch_requests_on_background_batch_id ON background_batch_requests USING btree (background_batch_id);


--
-- Name: index_background_batches_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_background_batches_on_user_id ON background_batches USING btree (user_id);


--
-- Name: index_balances_on_resource_id_and_resource_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_balances_on_resource_id_and_resource_type ON balances USING btree (resource_id, resource_type);


--
-- Name: index_company_partnerships_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_partnerships_on_company_id ON company_partnerships USING btree (company_id);


--
-- Name: index_company_positions_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_positions_on_company_id ON company_positions USING btree (company_id);


--
-- Name: index_company_positions_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_positions_on_person_id ON company_positions USING btree (person_id);


--
-- Name: index_company_positions_on_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_company_positions_on_start_date ON company_positions USING btree (start_date);


--
-- Name: index_contact_donor_accounts_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contact_donor_accounts_on_contact_id ON contact_donor_accounts USING btree (contact_id);


--
-- Name: index_contact_donor_accounts_on_donor_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contact_donor_accounts_on_donor_account_id ON contact_donor_accounts USING btree (donor_account_id);


--
-- Name: index_contact_notes_logs_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contact_notes_logs_on_contact_id ON contact_notes_logs USING btree (contact_id);


--
-- Name: index_contact_notes_logs_on_recorded_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contact_notes_logs_on_recorded_on ON contact_notes_logs USING btree (recorded_on);


--
-- Name: index_contact_people_on_contact_id_and_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_contact_people_on_contact_id_and_person_id ON contact_people USING btree (contact_id, person_id);


--
-- Name: index_contact_people_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contact_people_on_person_id ON contact_people USING btree (person_id);


--
-- Name: index_contact_referrals_on_referred_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contact_referrals_on_referred_to_id ON contact_referrals USING btree (referred_to_id);


--
-- Name: index_contacts_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_account_list_id ON contacts USING btree (account_list_id);


--
-- Name: index_contacts_on_last_donation_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_last_donation_date ON contacts USING btree (last_donation_date);


--
-- Name: index_contacts_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_status ON contacts USING btree (status);


--
-- Name: index_contacts_on_status_valid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_status_valid ON contacts USING btree (status_valid);


--
-- Name: index_contacts_on_tnt_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_tnt_id ON contacts USING btree (tnt_id);


--
-- Name: index_contacts_on_total_donations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_total_donations ON contacts USING btree (total_donations);


--
-- Name: index_currency_rates_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currency_rates_on_code ON currency_rates USING btree (code);


--
-- Name: index_currency_rates_on_code_and_exchanged_on; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_currency_rates_on_code_and_exchanged_on ON currency_rates USING btree (code, exchanged_on);


--
-- Name: index_currency_rates_on_exchanged_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currency_rates_on_exchanged_on ON currency_rates USING btree (exchanged_on);


--
-- Name: index_designation_profiles_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_designation_profiles_on_account_list_id ON designation_profiles USING btree (account_list_id);


--
-- Name: index_designation_profiles_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_designation_profiles_on_organization_id ON designation_profiles USING btree (organization_id);


--
-- Name: index_donations_on_appeal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donations_on_appeal_id ON donations USING btree (appeal_id);


--
-- Name: index_donations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donations_on_created_at ON donations USING btree (created_at);


--
-- Name: index_donations_on_des_acc_id_and_don_date_and_rem_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donations_on_des_acc_id_and_don_date_and_rem_id ON donations USING btree (designation_account_id, donation_date DESC, remote_id);


--
-- Name: index_donations_on_donation_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donations_on_donation_date ON donations USING btree (donation_date);


--
-- Name: index_donations_on_donor_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donations_on_donor_account_id ON donations USING btree (donor_account_id);


--
-- Name: index_donations_on_tnt_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donations_on_tnt_id ON donations USING btree (tnt_id);


--
-- Name: index_donor_account_people_on_donor_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donor_account_people_on_donor_account_id ON donor_account_people USING btree (donor_account_id);


--
-- Name: index_donor_account_people_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donor_account_people_on_person_id ON donor_account_people USING btree (person_id);


--
-- Name: index_donor_accounts_on_account_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donor_accounts_on_account_number ON donor_accounts USING btree (account_number);


--
-- Name: index_donor_accounts_on_acct_num_trig; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donor_accounts_on_acct_num_trig ON donor_accounts USING gin (account_number gin_trgm_ops);


--
-- Name: index_donor_accounts_on_last_donation_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donor_accounts_on_last_donation_date ON donor_accounts USING btree (last_donation_date);


--
-- Name: index_donor_accounts_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donor_accounts_on_organization_id ON donor_accounts USING btree (organization_id);


--
-- Name: index_donor_accounts_on_organization_id_and_account_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_donor_accounts_on_organization_id_and_account_number ON donor_accounts USING btree (organization_id, account_number);


--
-- Name: index_donor_accounts_on_total_donations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_donor_accounts_on_total_donations ON donor_accounts USING btree (total_donations);


--
-- Name: index_dup_record_pairs_on_record_one_type_and_record_one_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dup_record_pairs_on_record_one_type_and_record_one_id ON duplicate_record_pairs USING btree (record_one_type, record_one_id);


--
-- Name: index_dup_record_pairs_on_record_two_type_and_record_two_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dup_record_pairs_on_record_two_type_and_record_two_id ON duplicate_record_pairs USING btree (record_two_type, record_two_id);


--
-- Name: index_dup_record_pairs_on_record_types_and_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dup_record_pairs_on_record_types_and_ids ON duplicate_record_pairs USING btree (record_one_type, record_two_type, record_one_id, record_two_id);


--
-- Name: index_duplicate_record_pairs_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_duplicate_record_pairs_on_account_list_id ON duplicate_record_pairs USING btree (account_list_id);


--
-- Name: index_email_addresses_on_email_and_person_id_and_source; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_email_addresses_on_email_and_person_id_and_source ON email_addresses USING btree (email, person_id, source);


--
-- Name: index_email_addresses_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_addresses_on_person_id ON email_addresses USING btree (person_id);


--
-- Name: index_email_addresses_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_addresses_on_remote_id ON email_addresses USING btree (remote_id);


--
-- Name: index_email_addresses_on_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_addresses_on_source ON email_addresses USING btree (source);


--
-- Name: index_email_addresses_on_valid_values; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_addresses_on_valid_values ON email_addresses USING btree (valid_values);


--
-- Name: index_excluded_appeal_contacts_on_appeal_and_contact; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_excluded_appeal_contacts_on_appeal_and_contact ON appeal_excluded_appeal_contacts USING btree (appeal_id, contact_id);


--
-- Name: index_family_relationships_on_person_id_and_related_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_family_relationships_on_person_id_and_related_person_id ON family_relationships USING btree (person_id, related_person_id);


--
-- Name: index_family_relationships_on_related_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_family_relationships_on_related_person_id ON family_relationships USING btree (related_person_id);


--
-- Name: index_google_contacts_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_contacts_on_contact_id ON google_contacts USING btree (contact_id);


--
-- Name: index_google_contacts_on_google_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_contacts_on_google_account_id ON google_contacts USING btree (google_account_id);


--
-- Name: index_google_contacts_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_contacts_on_person_id ON google_contacts USING btree (person_id);


--
-- Name: index_google_contacts_on_person_id_and_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_contacts_on_person_id_and_contact_id ON google_contacts USING btree (person_id, contact_id);


--
-- Name: index_google_contacts_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_contacts_on_remote_id ON google_contacts USING btree (remote_id);


--
-- Name: index_google_email_activities_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_email_activities_on_activity_id ON google_email_activities USING btree (activity_id);


--
-- Name: index_google_email_activities_on_google_email_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_email_activities_on_google_email_id ON google_email_activities USING btree (google_email_id);


--
-- Name: index_google_emails_on_google_account_id_and_google_email_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_emails_on_google_account_id_and_google_email_id ON google_emails USING btree (google_account_id, google_email_id);


--
-- Name: index_google_events_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_events_on_activity_id ON google_events USING btree (activity_id);


--
-- Name: index_google_events_on_google_integration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_events_on_google_integration_id ON google_events USING btree (google_integration_id);


--
-- Name: index_google_integrations_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_integrations_on_account_list_id ON google_integrations USING btree (account_list_id);


--
-- Name: index_google_integrations_on_google_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_integrations_on_google_account_id ON google_integrations USING btree (google_account_id);


--
-- Name: index_google_plus_accounts_on_email_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_google_plus_accounts_on_email_address_id ON google_plus_accounts USING btree (email_address_id);


--
-- Name: index_imports_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_account_list_id ON imports USING btree (account_list_id);


--
-- Name: index_imports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_user_id ON imports USING btree (user_id);


--
-- Name: index_mail_chimp_accounts_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mail_chimp_accounts_on_account_list_id ON mail_chimp_accounts USING btree (account_list_id);


--
-- Name: index_mail_chimp_appeal_lists_on_appeal_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mail_chimp_appeal_lists_on_appeal_list_id ON mail_chimp_appeal_lists USING btree (appeal_list_id);


--
-- Name: index_mail_chimp_appeal_lists_on_mail_chimp_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mail_chimp_appeal_lists_on_mail_chimp_account_id ON mail_chimp_appeal_lists USING btree (mail_chimp_account_id);


--
-- Name: index_mail_chimp_members_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mail_chimp_members_on_email ON mail_chimp_members USING btree (email);


--
-- Name: index_mail_chimp_members_on_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mail_chimp_members_on_list_id ON mail_chimp_members USING btree (list_id);


--
-- Name: index_mail_chimp_members_on_mail_chimp_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mail_chimp_members_on_mail_chimp_account_id ON mail_chimp_members USING btree (mail_chimp_account_id);


--
-- Name: index_master_addresses_on_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_addresses_on_city ON master_addresses USING btree (city);


--
-- Name: index_master_addresses_on_country; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_addresses_on_country ON master_addresses USING btree (country);


--
-- Name: index_master_addresses_on_latitude; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_addresses_on_latitude ON master_addresses USING btree (latitude);


--
-- Name: index_master_addresses_on_postal_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_addresses_on_postal_code ON master_addresses USING btree (postal_code);


--
-- Name: index_master_addresses_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_addresses_on_state ON master_addresses USING btree (state);


--
-- Name: index_master_addresses_on_street; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_addresses_on_street ON master_addresses USING btree (street);


--
-- Name: index_master_companies_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_companies_on_name ON master_companies USING btree (name);


--
-- Name: index_master_person_donor_accounts_on_donor_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_person_donor_accounts_on_donor_account_id ON master_person_donor_accounts USING btree (donor_account_id);


--
-- Name: index_master_person_sources_on_master_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_master_person_sources_on_master_person_id ON master_person_sources USING btree (master_person_id);


--
-- Name: index_messages_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_account_list_id ON messages USING btree (account_list_id);


--
-- Name: index_messages_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_contact_id ON messages USING btree (contact_id);


--
-- Name: index_messages_on_from_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_from_id ON messages USING btree (from_id);


--
-- Name: index_messages_on_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_to_id ON messages USING btree (to_id);


--
-- Name: index_name_male_ratios_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_name_male_ratios_on_name ON name_male_ratios USING btree (name);


--
-- Name: index_nicknames_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_nicknames_on_name ON nicknames USING btree (name);


--
-- Name: index_nicknames_on_name_and_nickname; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_nicknames_on_name_and_nickname ON nicknames USING btree (name, nickname);


--
-- Name: index_nicknames_on_nickname; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_nicknames_on_nickname ON nicknames USING btree (nickname);


--
-- Name: index_notification_preferences_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_preferences_on_account_list_id ON notification_preferences USING btree (account_list_id);


--
-- Name: index_notification_preferences_on_notification_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notification_preferences_on_notification_type_id ON notification_preferences USING btree (notification_type_id);


--
-- Name: index_notification_preferences_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_notification_preferences_unique ON notification_preferences USING btree (user_id, account_list_id, notification_type_id);


--
-- Name: index_notifications_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_contact_id ON notifications USING btree (contact_id);


--
-- Name: index_notifications_on_donation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_donation_id ON notifications USING btree (donation_id);


--
-- Name: index_notifications_on_notification_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_notification_type_id ON notifications USING btree (notification_type_id);


--
-- Name: index_organizations_on_query_ini_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_query_ini_url ON organizations USING btree (query_ini_url);


--
-- Name: index_partner_status_logs_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_partner_status_logs_on_contact_id ON partner_status_logs USING btree (contact_id);


--
-- Name: index_partner_status_logs_on_recorded_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_partner_status_logs_on_recorded_on ON partner_status_logs USING btree (recorded_on);


--
-- Name: index_people_on_access_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_people_on_access_token ON people USING btree (access_token);


--
-- Name: index_people_on_anniversary_day; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_people_on_anniversary_day ON people USING btree (anniversary_day);


--
-- Name: index_people_on_anniversary_month; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_people_on_anniversary_month ON people USING btree (anniversary_month);


--
-- Name: index_people_on_first_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_people_on_first_name ON people USING btree (first_name);


--
-- Name: index_people_on_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_people_on_last_name ON people USING btree (last_name);


--
-- Name: index_people_on_master_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_people_on_master_person_id ON people USING btree (master_person_id);


--
-- Name: index_person_facebook_accounts_on_person_id_and_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_person_facebook_accounts_on_person_id_and_remote_id ON person_facebook_accounts USING btree (person_id, remote_id);


--
-- Name: index_person_facebook_accounts_on_person_id_and_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_person_facebook_accounts_on_person_id_and_username ON person_facebook_accounts USING btree (person_id, username);


--
-- Name: index_person_facebook_accounts_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_facebook_accounts_on_remote_id ON person_facebook_accounts USING btree (remote_id);


--
-- Name: index_person_google_accounts_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_google_accounts_on_person_id ON person_google_accounts USING btree (person_id);


--
-- Name: index_person_google_accounts_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_google_accounts_on_remote_id ON person_google_accounts USING btree (remote_id);


--
-- Name: index_person_key_accounts_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_key_accounts_on_person_id ON person_key_accounts USING btree (person_id);


--
-- Name: index_person_key_accounts_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_key_accounts_on_remote_id ON person_key_accounts USING btree (remote_id);


--
-- Name: index_person_linkedin_accounts_on_person_id_and_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_person_linkedin_accounts_on_person_id_and_remote_id ON person_linkedin_accounts USING btree (person_id, remote_id);


--
-- Name: index_person_linkedin_accounts_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_linkedin_accounts_on_remote_id ON person_linkedin_accounts USING btree (remote_id);


--
-- Name: index_person_options_on_key_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_person_options_on_key_and_user_id ON person_options USING btree (key, user_id);


--
-- Name: index_person_organization_accounts_on_last_download_attempt_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_organization_accounts_on_last_download_attempt_at ON person_organization_accounts USING btree (last_download_attempt_at);


--
-- Name: index_person_relay_accounts_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_relay_accounts_on_person_id ON person_relay_accounts USING btree (person_id);


--
-- Name: index_person_relay_accounts_on_relay_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_relay_accounts_on_relay_remote_id ON person_relay_accounts USING btree (relay_remote_id);


--
-- Name: index_person_twitter_accounts_on_person_id_and_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_person_twitter_accounts_on_person_id_and_remote_id ON person_twitter_accounts USING btree (person_id, remote_id);


--
-- Name: index_person_twitter_accounts_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_twitter_accounts_on_remote_id ON person_twitter_accounts USING btree (remote_id);


--
-- Name: index_person_websites_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_person_websites_on_person_id ON person_websites USING btree (person_id);


--
-- Name: index_phone_numbers_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_phone_numbers_on_person_id ON phone_numbers USING btree (person_id);


--
-- Name: index_phone_numbers_on_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_phone_numbers_on_remote_id ON phone_numbers USING btree (remote_id);


--
-- Name: index_phone_numbers_on_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_phone_numbers_on_source ON phone_numbers USING btree (source);


--
-- Name: index_phone_numbers_on_valid_values; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_phone_numbers_on_valid_values ON phone_numbers USING btree (valid_values);


--
-- Name: index_pledge_donations_on_donation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pledge_donations_on_donation_id ON pledge_donations USING btree (donation_id);


--
-- Name: index_pledge_donations_on_pledge_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pledge_donations_on_pledge_id ON pledge_donations USING btree (pledge_id);


--
-- Name: index_pledges_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pledges_on_account_list_id ON pledges USING btree (account_list_id);


--
-- Name: index_pledges_on_appeal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pledges_on_appeal_id ON pledges USING btree (appeal_id);


--
-- Name: index_pls_accounts_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pls_accounts_on_account_list_id ON pls_accounts USING btree (account_list_id);


--
-- Name: index_prayer_letters_accounts_on_account_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prayer_letters_accounts_on_account_list_id ON prayer_letters_accounts USING btree (account_list_id);


--
-- Name: index_remote_id_on_person_relay_account; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_remote_id_on_person_relay_account ON person_relay_accounts USING btree (lower((relay_remote_id)::text));


--
-- Name: index_taggings_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_context ON taggings USING btree (context);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tag_id ON taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable_id_and_taggable_type_and_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_id_and_taggable_type_and_context ON taggings USING btree (taggable_id, taggable_type, context);


--
-- Name: index_taggings_on_taggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_type ON taggings USING btree (taggable_type);


--
-- Name: index_taggings_on_tagger_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id ON taggings USING btree (tagger_id);


--
-- Name: index_taggings_on_tagger_id_and_tagger_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id_and_tagger_type ON taggings USING btree (tagger_id, tagger_type);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON tags USING btree (name);


--
-- Name: index_versions_on_item_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type ON versions USING btree (item_type, event, related_object_type, related_object_id, created_at, item_id);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON versions USING btree (item_type, item_id);


--
-- Name: index_versions_on_whodunnit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_whodunnit ON versions USING btree (whodunnit);


--
-- Name: mail_chimp_members_email_list_account_uniq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mail_chimp_members_email_list_account_uniq ON mail_chimp_members USING btree (mail_chimp_account_id, list_id, email);


--
-- Name: notification_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notification_index ON notifications USING btree (contact_id, notification_type_id, donation_id);


--
-- Name: organization_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX organization_remote_id ON master_person_sources USING btree (organization_id, remote_id);


--
-- Name: person_account; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX person_account ON master_person_donor_accounts USING btree (master_person_id, donor_account_id);


--
-- Name: person_relay_accounts_on_lower_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX person_relay_accounts_on_lower_remote_id ON person_relay_accounts USING btree (lower((remote_id)::text));


--
-- Name: picture_of; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX picture_of ON pictures USING btree (picture_of_id, picture_of_type);


--
-- Name: recommendations_designation_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recommendations_designation_account_id ON donation_amount_recommendations USING btree (designation_account_id);


--
-- Name: recommendations_donor_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recommendations_donor_account_id ON donation_amount_recommendations USING btree (donor_account_id);


--
-- Name: referrals; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX referrals ON contact_referrals USING btree (referred_by_id, referred_to_id);


--
-- Name: related_object_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX related_object_index ON versions USING btree (item_type, related_object_type, related_object_id, created_at);


--
-- Name: taggings_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX taggings_idx ON taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);


--
-- Name: taggings_idy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_idy ON taggings USING btree (taggable_id, taggable_type, tagger_id, context);


--
-- Name: tags_on_lower_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tags_on_lower_name ON tags USING btree (lower((name)::text));


--
-- Name: unique_account; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_account ON account_list_entries USING btree (account_list_id, designation_account_id);


--
-- Name: unique_company_account; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_company_account ON company_partnerships USING btree (account_list_id, company_id);


--
-- Name: unique_designation_org; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_designation_org ON designation_accounts USING btree (organization_id, designation_number);


--
-- Name: unique_donation_designation; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_donation_designation ON donations USING btree (designation_account_id, remote_id);


--
-- Name: unique_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_remote_id ON designation_profiles USING btree (user_id, organization_id, remote_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: user_id_and_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_id_and_organization_id ON person_organization_accounts USING btree (person_id, organization_id);


--
-- Name: appeal_excluded_appeal_contacts appeal_excluded_appeal_contacts_appeal_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appeal_excluded_appeal_contacts
    ADD CONSTRAINT appeal_excluded_appeal_contacts_appeal_id_fk FOREIGN KEY (appeal_id) REFERENCES appeals(id) ON DELETE CASCADE;


--
-- Name: appeal_excluded_appeal_contacts appeal_excluded_appeal_contacts_contact_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appeal_excluded_appeal_contacts
    ADD CONSTRAINT appeal_excluded_appeal_contacts_contact_id_fk FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE;


--
-- Name: background_batch_requests background_batch_requests_background_batch_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY background_batch_requests
    ADD CONSTRAINT background_batch_requests_background_batch_id_fk FOREIGN KEY (background_batch_id) REFERENCES background_batches(id);


--
-- Name: background_batches background_batches_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY background_batches
    ADD CONSTRAINT background_batches_user_id_fk FOREIGN KEY (user_id) REFERENCES people(id);


--
-- Name: donation_amount_recommendations donation_amount_recommendations_designation_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donation_amount_recommendations
    ADD CONSTRAINT donation_amount_recommendations_designation_account_id_fk FOREIGN KEY (designation_account_id) REFERENCES designation_accounts(id) ON DELETE SET NULL;


--
-- Name: donation_amount_recommendations donation_amount_recommendations_donor_account_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY donation_amount_recommendations
    ADD CONSTRAINT donation_amount_recommendations_donor_account_id_fk FOREIGN KEY (donor_account_id) REFERENCES donor_accounts(id) ON DELETE SET NULL;


--
-- Name: master_person_sources master_person_sources_master_person_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY master_person_sources
    ADD CONSTRAINT master_person_sources_master_person_id_fk FOREIGN KEY (master_person_id) REFERENCES master_people(id);


--
-- Name: people people_master_person_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_master_person_id_fk FOREIGN KEY (master_person_id) REFERENCES master_people(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

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

INSERT INTO schema_migrations (version) VALUES ('20160627171818');

INSERT INTO schema_migrations (version) VALUES ('20160728174747');

INSERT INTO schema_migrations (version) VALUES ('20160809235201');

INSERT INTO schema_migrations (version) VALUES ('20160811145356');

INSERT INTO schema_migrations (version) VALUES ('20160928195843');

INSERT INTO schema_migrations (version) VALUES ('20161007231427');

INSERT INTO schema_migrations (version) VALUES ('20161119005933');

INSERT INTO schema_migrations (version) VALUES ('20161128055225');

INSERT INTO schema_migrations (version) VALUES ('20161130200449');

INSERT INTO schema_migrations (version) VALUES ('20161214195836');

INSERT INTO schema_migrations (version) VALUES ('20161216004043');

INSERT INTO schema_migrations (version) VALUES ('20161216004126');

INSERT INTO schema_migrations (version) VALUES ('20161216004128');

INSERT INTO schema_migrations (version) VALUES ('20161216004129');

INSERT INTO schema_migrations (version) VALUES ('20161216004130');

INSERT INTO schema_migrations (version) VALUES ('20161216004131');

INSERT INTO schema_migrations (version) VALUES ('20161216004132');

INSERT INTO schema_migrations (version) VALUES ('20161216004133');

INSERT INTO schema_migrations (version) VALUES ('20161216004134');

INSERT INTO schema_migrations (version) VALUES ('20161216004135');

INSERT INTO schema_migrations (version) VALUES ('20161216004136');

INSERT INTO schema_migrations (version) VALUES ('20161216004137');

INSERT INTO schema_migrations (version) VALUES ('20161216004138');

INSERT INTO schema_migrations (version) VALUES ('20161216004139');

INSERT INTO schema_migrations (version) VALUES ('20161216004140');

INSERT INTO schema_migrations (version) VALUES ('20161216004141');

INSERT INTO schema_migrations (version) VALUES ('20161216004142');

INSERT INTO schema_migrations (version) VALUES ('20161216004143');

INSERT INTO schema_migrations (version) VALUES ('20161216004144');

INSERT INTO schema_migrations (version) VALUES ('20161216004145');

INSERT INTO schema_migrations (version) VALUES ('20161216004146');

INSERT INTO schema_migrations (version) VALUES ('20161216004147');

INSERT INTO schema_migrations (version) VALUES ('20161216004148');

INSERT INTO schema_migrations (version) VALUES ('20161216004149');

INSERT INTO schema_migrations (version) VALUES ('20161216004150');

INSERT INTO schema_migrations (version) VALUES ('20161216004151');

INSERT INTO schema_migrations (version) VALUES ('20161216004152');

INSERT INTO schema_migrations (version) VALUES ('20161216004153');

INSERT INTO schema_migrations (version) VALUES ('20161216004154');

INSERT INTO schema_migrations (version) VALUES ('20161216004155');

INSERT INTO schema_migrations (version) VALUES ('20161216004156');

INSERT INTO schema_migrations (version) VALUES ('20161216004157');

INSERT INTO schema_migrations (version) VALUES ('20161216004158');

INSERT INTO schema_migrations (version) VALUES ('20161216004159');

INSERT INTO schema_migrations (version) VALUES ('20161216004160');

INSERT INTO schema_migrations (version) VALUES ('20161216004161');

INSERT INTO schema_migrations (version) VALUES ('20161216004162');

INSERT INTO schema_migrations (version) VALUES ('20161216004200');

INSERT INTO schema_migrations (version) VALUES ('20161216004201');

INSERT INTO schema_migrations (version) VALUES ('20161216004202');

INSERT INTO schema_migrations (version) VALUES ('20161216004203');

INSERT INTO schema_migrations (version) VALUES ('20161216004205');

INSERT INTO schema_migrations (version) VALUES ('20161216004206');

INSERT INTO schema_migrations (version) VALUES ('20161216004207');

INSERT INTO schema_migrations (version) VALUES ('20161216004208');

INSERT INTO schema_migrations (version) VALUES ('20161216004209');

INSERT INTO schema_migrations (version) VALUES ('20161216004211');

INSERT INTO schema_migrations (version) VALUES ('20161216004212');

INSERT INTO schema_migrations (version) VALUES ('20161216004213');

INSERT INTO schema_migrations (version) VALUES ('20161216004214');

INSERT INTO schema_migrations (version) VALUES ('20161216004215');

INSERT INTO schema_migrations (version) VALUES ('20161216004216');

INSERT INTO schema_migrations (version) VALUES ('20161216004217');

INSERT INTO schema_migrations (version) VALUES ('20161216004218');

INSERT INTO schema_migrations (version) VALUES ('20161216004220');

INSERT INTO schema_migrations (version) VALUES ('20161216004221');

INSERT INTO schema_migrations (version) VALUES ('20161216004222');

INSERT INTO schema_migrations (version) VALUES ('20161216004223');

INSERT INTO schema_migrations (version) VALUES ('20161216004224');

INSERT INTO schema_migrations (version) VALUES ('20161216004225');

INSERT INTO schema_migrations (version) VALUES ('20161216004226');

INSERT INTO schema_migrations (version) VALUES ('20161216004228');

INSERT INTO schema_migrations (version) VALUES ('20161216004229');

INSERT INTO schema_migrations (version) VALUES ('20161216004231');

INSERT INTO schema_migrations (version) VALUES ('20161216004232');

INSERT INTO schema_migrations (version) VALUES ('20161216004233');

INSERT INTO schema_migrations (version) VALUES ('20161216004234');

INSERT INTO schema_migrations (version) VALUES ('20161216004235');

INSERT INTO schema_migrations (version) VALUES ('20161216004236');

INSERT INTO schema_migrations (version) VALUES ('20161216004239');

INSERT INTO schema_migrations (version) VALUES ('20170109201920');

INSERT INTO schema_migrations (version) VALUES ('20170109220413');

INSERT INTO schema_migrations (version) VALUES ('20170209201959');

INSERT INTO schema_migrations (version) VALUES ('20170209205030');

INSERT INTO schema_migrations (version) VALUES ('20170210004955');

INSERT INTO schema_migrations (version) VALUES ('20170217220712');

INSERT INTO schema_migrations (version) VALUES ('20170221212815');

INSERT INTO schema_migrations (version) VALUES ('20170223165218');

INSERT INTO schema_migrations (version) VALUES ('20170301173502');

INSERT INTO schema_migrations (version) VALUES ('20170306203922');

INSERT INTO schema_migrations (version) VALUES ('20170307220854');

INSERT INTO schema_migrations (version) VALUES ('20170314185145');

INSERT INTO schema_migrations (version) VALUES ('20170315222249');

INSERT INTO schema_migrations (version) VALUES ('20170316042808');

INSERT INTO schema_migrations (version) VALUES ('20170317205005');

INSERT INTO schema_migrations (version) VALUES ('20170322001657');

INSERT INTO schema_migrations (version) VALUES ('20170330210139');

INSERT INTO schema_migrations (version) VALUES ('20170330210159');

INSERT INTO schema_migrations (version) VALUES ('20170404210716');

INSERT INTO schema_migrations (version) VALUES ('20170404211028');

INSERT INTO schema_migrations (version) VALUES ('20170404211527');

INSERT INTO schema_migrations (version) VALUES ('20170405190646');

INSERT INTO schema_migrations (version) VALUES ('20170407154800');

INSERT INTO schema_migrations (version) VALUES ('20170418035928');

INSERT INTO schema_migrations (version) VALUES ('20170418040007');

INSERT INTO schema_migrations (version) VALUES ('20170418040030');

INSERT INTO schema_migrations (version) VALUES ('20170419001725');

INSERT INTO schema_migrations (version) VALUES ('20170419004646');

INSERT INTO schema_migrations (version) VALUES ('20170419141659');

INSERT INTO schema_migrations (version) VALUES ('20170419145350');

INSERT INTO schema_migrations (version) VALUES ('20170420161008');

INSERT INTO schema_migrations (version) VALUES ('20170511182601');

INSERT INTO schema_migrations (version) VALUES ('20170511182602');

INSERT INTO schema_migrations (version) VALUES ('20170511182604');

INSERT INTO schema_migrations (version) VALUES ('20170518165122');

INSERT INTO schema_migrations (version) VALUES ('20170529000340');

INSERT INTO schema_migrations (version) VALUES ('20170529002918');

INSERT INTO schema_migrations (version) VALUES ('20170707013656');

INSERT INTO schema_migrations (version) VALUES ('20170711194415');

INSERT INTO schema_migrations (version) VALUES ('20170728214336');

INSERT INTO schema_migrations (version) VALUES ('20170728221932');

INSERT INTO schema_migrations (version) VALUES ('20170731185156');

INSERT INTO schema_migrations (version) VALUES ('20170801182230');

INSERT INTO schema_migrations (version) VALUES ('20170803172858');

INSERT INTO schema_migrations (version) VALUES ('20170810174948');

INSERT INTO schema_migrations (version) VALUES ('20170814230054');

INSERT INTO schema_migrations (version) VALUES ('20170816144835');

INSERT INTO schema_migrations (version) VALUES ('20170817184253');

INSERT INTO schema_migrations (version) VALUES ('20170824151005');

INSERT INTO schema_migrations (version) VALUES ('20170829192854');

INSERT INTO schema_migrations (version) VALUES ('20170829211453');

INSERT INTO schema_migrations (version) VALUES ('20170829212715');

INSERT INTO schema_migrations (version) VALUES ('20170829220006');

INSERT INTO schema_migrations (version) VALUES ('20170830234109');

INSERT INTO schema_migrations (version) VALUES ('20170831194616');

INSERT INTO schema_migrations (version) VALUES ('20170905043431');

INSERT INTO schema_migrations (version) VALUES ('20170905044350');

INSERT INTO schema_migrations (version) VALUES ('20170906162655');

INSERT INTO schema_migrations (version) VALUES ('20170907182701');

INSERT INTO schema_migrations (version) VALUES ('20170911035021');

INSERT INTO schema_migrations (version) VALUES ('20170912232954');

INSERT INTO schema_migrations (version) VALUES ('20170913013837');

INSERT INTO schema_migrations (version) VALUES ('20170918022812');

INSERT INTO schema_migrations (version) VALUES ('20170918022824');

INSERT INTO schema_migrations (version) VALUES ('20170921212918');

INSERT INTO schema_migrations (version) VALUES ('20170921213101');

INSERT INTO schema_migrations (version) VALUES ('20170922152101');

INSERT INTO schema_migrations (version) VALUES ('20170925223827');

INSERT INTO schema_migrations (version) VALUES ('20170926155821');

INSERT INTO schema_migrations (version) VALUES ('20170926162140');

INSERT INTO schema_migrations (version) VALUES ('20171002211135');

INSERT INTO schema_migrations (version) VALUES ('20171002215149');

INSERT INTO schema_migrations (version) VALUES ('20171004041321');

INSERT INTO schema_migrations (version) VALUES ('20171006024505');

INSERT INTO schema_migrations (version) VALUES ('20171006035430');

INSERT INTO schema_migrations (version) VALUES ('20171011173827');

INSERT INTO schema_migrations (version) VALUES ('20171023022515');

INSERT INTO schema_migrations (version) VALUES ('20171024045755');

INSERT INTO schema_migrations (version) VALUES ('20171101004028');

INSERT INTO schema_migrations (version) VALUES ('20171102140700');

INSERT INTO schema_migrations (version) VALUES ('20171108032537');

INSERT INTO schema_migrations (version) VALUES ('20171113062557');

INSERT INTO schema_migrations (version) VALUES ('20180123202819');

INSERT INTO schema_migrations (version) VALUES ('20180130143557');

INSERT INTO schema_migrations (version) VALUES ('20180201214927');

