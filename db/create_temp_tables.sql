-- Temp Table
-- Name: tmp_account_list_coaches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_account_list_coaches (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    coach_id uuid,
	    account_list_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_account_list_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_account_list_entries (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    account_list_id uuid,
	    designation_account_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_account_list_invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_account_list_invites (
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


-- Temp Table
-- Name: tmp_account_list_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_account_list_users (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    user_id uuid,
	    account_list_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_account_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_account_lists (
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


-- Temp Table
-- Name: tmp_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_activities (
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


-- Temp Table
-- Name: tmp_activity_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_activity_comments (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    activity_id uuid,
	    person_id uuid,
	    body text,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_activity_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_activity_contacts (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    activity_id uuid,
	    contact_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_addresses (
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


-- Temp Table
-- Name: tmp_admin_impersonation_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_admin_impersonation_logs (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    reason text NOT NULL,
	    impersonator_id uuid NOT NULL,
	    impersonated_id uuid NOT NULL,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_admin_reset_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_admin_reset_logs (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    admin_resetting_id uuid,
	    resetted_user_id uuid,
	    reason character varying,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL,
	    completed_at timestamp without time zone
);


-- Temp Table
-- Name: tmp_appeal_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_appeal_contacts (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    appeal_id uuid,
	    contact_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_appeal_excluded_appeal_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_appeal_excluded_appeal_contacts (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    appeal_id uuid,
	    contact_id uuid,
	    reasons text[],
	    created_at timestamp without time zone,
	    updated_at timestamp without time zone
);


-- Temp Table
-- Name: tmp_appeals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_appeals (
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


-- Temp Table
-- Name: tmp_background_batch_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_background_batch_requests (
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


-- Temp Table
-- Name: tmp_background_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_background_batches (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    batch_id character varying,
	    user_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_balances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_balances (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    balance numeric,
	    resource_id uuid,
	    resource_type character varying,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_companies (
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


-- Temp Table
-- Name: tmp_company_partnerships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_company_partnerships (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    account_list_id uuid,
	    company_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_company_positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_company_positions (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    person_id uuid NOT NULL,
	    company_id uuid NOT NULL,
	    start_date date,
	    end_date date,
	    "position" character varying,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_contact_donor_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_contact_donor_accounts (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    contact_id uuid,
	    donor_account_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_contact_notes_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_contact_notes_logs (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    contact_id uuid,
	    recorded_on date,
	    notes text,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_contact_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_contact_people (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    contact_id uuid,
	    person_id uuid,
	    "primary" boolean,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_contact_referrals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_contact_referrals (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    referred_by_id uuid,
	    referred_to_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_contacts (
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


-- Temp Table
-- Name: tmp_currency_aliases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_currency_aliases (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    alias_code character varying NOT NULL,
	    rate_api_code character varying NOT NULL,
	    ratio numeric NOT NULL,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_currency_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_currency_rates (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    exchanged_on date NOT NULL,
	    code character varying NOT NULL,
	    rate numeric(20,10) NOT NULL,
	    source character varying NOT NULL
);


-- Temp Table
-- Name: tmp_designation_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_designation_accounts (
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


-- Temp Table
-- Name: tmp_designation_profile_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_designation_profile_accounts (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    designation_profile_id uuid,
	    designation_account_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_designation_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_designation_profiles (
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


-- Temp Table
-- Name: tmp_donation_amount_recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_donation_amount_recommendations (
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


-- Temp Table
-- Name: tmp_donations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_donations (
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


-- Temp Table
-- Name: tmp_donor_account_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_donor_account_people (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    donor_account_id uuid,
	    person_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_donor_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_donor_accounts (
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


-- Temp Table
-- Name: tmp_duplicate_record_pairs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_duplicate_record_pairs (
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


-- Temp Table
-- Name: tmp_email_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_email_addresses (
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


-- Temp Table
-- Name: tmp_export_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_export_logs (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    type character varying,
	    params text,
	    user_id uuid,
	    export_at timestamp without time zone,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_family_relationships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_family_relationships (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    person_id uuid,
	    related_person_id uuid,
	    relationship character varying NOT NULL,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_google_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_google_contacts (
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


-- Temp Table
-- Name: tmp_google_email_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_google_email_activities (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    google_email_id uuid,
	    activity_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_google_emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_google_emails (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    google_account_id uuid,
	    google_email_id bigint,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_google_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_google_events (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    activity_id uuid,
	    google_integration_id uuid,
	    google_event_id character varying,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL,
	    calendar_id character varying
);


-- Temp Table
-- Name: tmp_google_integrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_google_integrations (
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


-- Temp Table
-- Name: tmp_google_plus_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_google_plus_accounts (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    account_id character varying,
	    profile_picture_link character varying,
	    email_address_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_help_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_help_requests (
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


-- Temp Table
-- Name: tmp_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_imports (
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
	    source_account_id uuid,
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


-- Temp Table
-- Name: tmp_mail_chimp_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_mail_chimp_accounts (
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


-- Temp Table
-- Name: tmp_mail_chimp_appeal_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_mail_chimp_appeal_lists (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    mail_chimp_account_id uuid NOT NULL,
	    appeal_list_id character varying NOT NULL,
	    appeal_id uuid NOT NULL,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_mail_chimp_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_mail_chimp_members (
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


-- Temp Table
-- Name: tmp_master_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_master_addresses (
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


-- Temp Table
-- Name: tmp_master_companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_master_companies (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    name character varying,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_master_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_master_people (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_master_person_donor_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_master_person_donor_accounts (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    master_person_id uuid,
	    donor_account_id uuid,
	    "primary" boolean DEFAULT false NOT NULL,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_master_person_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_master_person_sources (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    master_person_id uuid,
	    organization_id uuid,
	    remote_id character varying,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_messages (
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


-- Temp Table
-- Name: tmp_name_male_ratios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_name_male_ratios (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    name character varying NOT NULL,
	    male_ratio double precision NOT NULL,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_nicknames; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_nicknames (
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


-- Temp Table
-- Name: tmp_notification_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_notification_preferences (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    notification_type_id uuid,
	    account_list_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL,
	    user_id uuid,
	    email boolean DEFAULT true,
	    task boolean DEFAULT true
);


-- Temp Table
-- Name: tmp_notification_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_notification_types (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    type character varying,
	    description text,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL,
	    description_for_email text
);


-- Temp Table
-- Name: tmp_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_notifications (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    contact_id uuid,
	    notification_type_id uuid,
	    event_date timestamp without time zone,
	    cleared boolean DEFAULT false NOT NULL,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL,
	    donation_id uuid
);


-- Temp Table
-- Name: tmp_organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_organizations (
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


-- Temp Table
-- Name: tmp_partner_status_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_partner_status_logs (
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


-- Temp Table
-- Name: tmp_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_people (
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


-- Temp Table
-- Name: tmp_person_facebook_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_person_facebook_accounts (
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


-- Temp Table
-- Name: tmp_person_google_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_person_google_accounts (
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


-- Temp Table
-- Name: tmp_person_key_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_person_key_accounts (
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


-- Temp Table
-- Name: tmp_person_linkedin_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_person_linkedin_accounts (
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


-- Temp Table
-- Name: tmp_person_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_person_options (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    key character varying NOT NULL,
	    value character varying,
	    user_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_person_organization_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_person_organization_accounts (
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


-- Temp Table
-- Name: tmp_person_relay_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_person_relay_accounts (
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


-- Temp Table
-- Name: tmp_person_twitter_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_person_twitter_accounts (
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


-- Temp Table
-- Name: tmp_person_websites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_person_websites (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    person_id uuid,
	    url text,
	    "primary" boolean DEFAULT false,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_phone_numbers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_phone_numbers (
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


-- Temp Table
-- Name: tmp_pictures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_pictures (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    picture_of_id uuid,
	    picture_of_type character varying,
	    image character varying,
	    "primary" boolean DEFAULT false NOT NULL,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_pledge_donations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_pledge_donations (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    pledge_id uuid,
	    donation_id uuid,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_pledges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_pledges (
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


-- Temp Table
-- Name: tmp_pls_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_pls_accounts (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    account_list_id uuid,
	    oauth2_token character varying,
	    valid_token boolean DEFAULT true,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_prayer_letters_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_prayer_letters_accounts (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    token character varying,
	    secret character varying,
	    valid_token boolean DEFAULT true,
	    created_at timestamp without time zone NOT NULL,
	    updated_at timestamp without time zone NOT NULL,
	    account_list_id uuid,
	    oauth2_token character varying
);


-- Temp Table
-- Name: tmp_taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_taggings (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    tag_id uuid,
	    taggable_id uuid,
	    taggable_type character varying,
	    tagger_id integer,
	    tagger_type character varying,
	    context character varying(128),
	    created_at timestamp without time zone NOT NULL
);


-- Temp Table
-- Name: tmp_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tmp_tags (
	    id uuid DEFAULT uuid_generate_v4() NOT NULL,
	    name character varying,
	    taggings_count integer DEFAULT 0
);

