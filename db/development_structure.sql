--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
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
-- Name: workcamp_assignments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workcamp_assignments (
    id integer NOT NULL,
    apply_form_id integer,
    workcamp_id integer,
    "order" integer NOT NULL,
    accepted timestamp without time zone,
    rejected timestamp without time zone,
    asked timestamp without time zone,
    infosheeted timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: accepted_assignments; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW accepted_assignments AS
    SELECT a.apply_form_id, min(a."order") AS "order" FROM workcamp_assignments a WHERE ((a.accepted IS NOT NULL) AND (a.rejected IS NULL)) GROUP BY a.apply_form_id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE countries (
    id integer NOT NULL,
    code character varying(2) NOT NULL,
    name_cs character varying(255),
    name_en character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    triple_code character varying(3)
);


--
-- Name: workcamps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workcamps (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    old_schema_key integer,
    country_id integer NOT NULL,
    organization_id integer NOT NULL,
    language character varying(255),
    begin date,
    "end" date,
    capacity integer,
    places integer NOT NULL,
    places_for_males integer NOT NULL,
    places_for_females integer NOT NULL,
    minimal_age integer DEFAULT 18,
    maximal_age integer DEFAULT 99,
    area text,
    accomodation text,
    workdesc text,
    notes text,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    extra_fee numeric(10,2),
    extra_fee_currency character varying(255),
    region character varying(255),
    capacity_natives integer,
    capacity_teenagers integer,
    capacity_males integer,
    capacity_females integer,
    airport character varying(255),
    train character varying(255),
    publish_mode character varying(255) DEFAULT 'ALWAYS'::character varying NOT NULL,
    accepted_places integer DEFAULT 0 NOT NULL,
    accepted_places_males integer DEFAULT 0 NOT NULL,
    accepted_places_females integer DEFAULT 0 NOT NULL,
    asked_for_places integer DEFAULT 0 NOT NULL,
    asked_for_places_males integer DEFAULT 0 NOT NULL,
    asked_for_places_females integer DEFAULT 0 NOT NULL,
    type character varying(255) DEFAULT 'Outgoing::Workcamp'::character varying NOT NULL,
    sci_code character varying(255),
    longitude numeric(11,7),
    latitude numeric(11,7),
    state character varying(255),
    sci_id integer,
    requirements text
);


--
-- Name: active_countries_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW active_countries_view AS
    SELECT DISTINCT c.id, c.code, c.name_cs, c.name_en, c.created_at, c.updated_at, c.triple_code FROM (countries c JOIN workcamps w ON ((c.id = w.country_id)));


--
-- Name: apply_forms; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE apply_forms (
    id integer NOT NULL,
    volunteer_id integer,
    fee numeric(10,2) DEFAULT 2200.0 NOT NULL,
    cancelled timestamp without time zone,
    general_remarks text,
    motivation text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    current_workcamp_id_cached integer,
    current_assignment_id_cached integer,
    type character varying(255) DEFAULT 'Outgoing::ApplyForm'::character varying NOT NULL,
    confirmed timestamp without time zone
);


--
-- Name: apply_forms_cached_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW apply_forms_cached_view AS
    SELECT application.id, application.volunteer_id, application.fee, application.cancelled, application.general_remarks, application.motivation, application.created_at, application.updated_at, application.current_workcamp_id_cached, application.current_assignment_id_cached, workcamp_assignments.accepted, workcamp_assignments.rejected, workcamp_assignments.asked, workcamp_assignments.infosheeted FROM (apply_forms application LEFT JOIN workcamp_assignments ON ((application.current_assignment_id_cached = workcamp_assignments.id)));


--
-- Name: apply_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE apply_forms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: apply_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE apply_forms_id_seq OWNED BY apply_forms.id;


--
-- Name: pending_assignments; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW pending_assignments AS
    SELECT a.apply_form_id, min(a."order") AS "order" FROM workcamp_assignments a WHERE ((((a.accepted IS NULL) AND (a.asked IS NULL)) AND (a.rejected IS NULL)) OR ((a.asked IS NOT NULL) AND (a.rejected IS NULL))) GROUP BY a.apply_form_id;


--
-- Name: rejected_assignments; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW rejected_assignments AS
    SELECT a.apply_form_id, a."order" FROM (workcamp_assignments a JOIN (SELECT c.apply_form_id, max(c."order") AS maximum FROM workcamp_assignments c GROUP BY c.apply_form_id) b USING (apply_form_id)) WHERE ((a."order" = b.maximum) AND (a.rejected IS NOT NULL));


--
-- Name: apply_forms_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW apply_forms_view AS
    SELECT application.id, application.volunteer_id, application.fee, application.cancelled, application.general_remarks, application.motivation, application.created_at, application.updated_at, application.current_workcamp_id_cached, application.current_assignment_id_cached, workcamp.workcamp_id AS current_workcamp_id, workcamp.current_assignment_id, workcamp.accepted, workcamp.rejected, workcamp.asked, workcamp.infosheeted FROM (apply_forms application LEFT JOIN (SELECT assignment.id AS current_assignment_id, assignment.apply_form_id, assignment.workcamp_id, assignment.accepted, assignment.rejected, assignment.asked, assignment.infosheeted FROM (workcamp_assignments assignment JOIN (SELECT assignments.apply_form_id, min(assignments."order") AS "order" FROM ((SELECT pending_assignments.apply_form_id, pending_assignments."order" FROM pending_assignments UNION SELECT accepted_assignments.apply_form_id, accepted_assignments."order" FROM accepted_assignments) UNION SELECT rejected_assignments.apply_form_id, rejected_assignments."order" FROM rejected_assignments) assignments GROUP BY assignments.apply_form_id) latest ON (((assignment.apply_form_id = latest.apply_form_id) AND (assignment."order" = latest."order"))))) workcamp ON ((workcamp.apply_form_id = application.id)));


--
-- Name: bookings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bookings (
    id integer NOT NULL,
    workcamp_id integer,
    organization_id integer,
    country_id integer,
    gender character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: bookings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bookings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bookings_id_seq OWNED BY bookings.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments (
    id integer NOT NULL,
    title character varying(50) DEFAULT ''::character varying,
    comment text DEFAULT ''::text,
    created_at timestamp without time zone NOT NULL,
    commentable_id integer DEFAULT 0 NOT NULL,
    commentable_type character varying(15) DEFAULT ''::character varying NOT NULL,
    user_id integer DEFAULT 0 NOT NULL
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE countries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE countries_id_seq OWNED BY countries.id;


--
-- Name: email_contacts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE email_contacts (
    id integer NOT NULL,
    active boolean DEFAULT false,
    address character varying(255) NOT NULL,
    name character varying(255),
    notes character varying(255),
    organization_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    kind character varying(255)
);


--
-- Name: email_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE email_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE email_contacts_id_seq OWNED BY email_contacts.id;


--
-- Name: email_templates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE email_templates (
    id integer NOT NULL,
    action character varying(255),
    description character varying(255),
    subject character varying(255),
    wrap_into_template character varying(255) DEFAULT 'mail'::character varying,
    body text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: email_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE email_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE email_templates_id_seq OWNED BY email_templates.id;


--
-- Name: hostings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE hostings (
    id integer NOT NULL,
    workcamp_id integer,
    partner_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: hostings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE hostings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hostings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hostings_id_seq OWNED BY hostings.id;


--
-- Name: import_changes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE import_changes (
    id integer NOT NULL,
    field character varying(255) NOT NULL,
    value text NOT NULL,
    diff text,
    workcamp_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: import_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE import_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE import_changes_id_seq OWNED BY import_changes.id;


--
-- Name: infosheets; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE infosheets (
    id integer NOT NULL,
    workcamp_id integer,
    document_file_name character varying(255),
    document_content_type character varying(255),
    document_file_size integer,
    document_updated_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notes text
);


--
-- Name: infosheets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE infosheets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infosheets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE infosheets_id_seq OWNED BY infosheets.id;


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE languages (
    id integer NOT NULL,
    code character varying(2),
    triple_code character varying(3) NOT NULL,
    name_cs character varying(255),
    name_en character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: languages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE languages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: languages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE languages_id_seq OWNED BY languages.id;


--
-- Name: leaderships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE leaderships (
    id integer NOT NULL,
    person_id integer,
    workcamp_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: leaderships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE leaderships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leaderships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE leaderships_id_seq OWNED BY leaderships.id;


--
-- Name: networks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE networks (
    id integer NOT NULL,
    name character varying(255),
    web character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: networks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE networks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: networks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE networks_id_seq OWNED BY networks.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE organizations (
    id integer NOT NULL,
    country_id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(255) NOT NULL,
    address character varying(255),
    contact_person character varying(255),
    phone character varying(255),
    mobile character varying(255),
    fax character varying(255),
    website character varying(2048),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
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
-- Name: partners; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE partners (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    contact_person character varying(255),
    phone character varying(255),
    email character varying(255),
    address character varying(2048),
    website character varying(2048),
    negotiations_notes character varying(5096),
    notes text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: partners_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE partners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: partners_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE partners_id_seq OWNED BY partners.id;


--
-- Name: partnerships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE partnerships (
    id integer NOT NULL,
    description character varying(255),
    network_id integer,
    organization_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: partnerships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE partnerships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: partnerships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE partnerships_id_seq OWNED BY partnerships.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE payments (
    id integer NOT NULL,
    apply_form_id integer,
    amount numeric(10,2) NOT NULL,
    received date NOT NULL,
    description character varying(1024),
    account character varying(255),
    mean character varying(255) NOT NULL,
    returned_date date,
    returned_amount numeric(10,2),
    return_reason character varying(1024),
    bank_code character varying(4),
    spec_symbol character varying(255),
    var_symbol character varying(255),
    const_symbol character varying(255),
    name character varying(255)
);


--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE payments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE payments_id_seq OWNED BY payments.id;


--
-- Name: people; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE people (
    id integer NOT NULL,
    firstname character varying(255) NOT NULL,
    lastname character varying(255) NOT NULL,
    gender character varying(255) NOT NULL,
    old_schema_key integer,
    email character varying(255),
    phone character varying(255),
    birthdate date,
    birthnumber character varying(255),
    nationality character varying(255),
    occupation character varying(255),
    account character varying(255),
    emergency_name character varying(255),
    emergency_day character varying(255),
    emergency_night character varying(255),
    speak_well character varying(255),
    speak_some character varying(255),
    special_needs text,
    past_experience text,
    comments text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    fax character varying(255),
    street character varying(255),
    city character varying(255),
    zipcode character varying(255),
    contact_street character varying(255),
    contact_city character varying(255),
    contact_zipcode character varying(255),
    birthplace character varying(255),
    type character varying(255) DEFAULT 'Volunteer'::character varying NOT NULL,
    workcamp_id integer,
    country_id integer,
    note text,
    organization_id integer
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
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_id integer,
    taggable_type character varying(255),
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
    name character varying(255) NOT NULL,
    color character varying(7) DEFAULT '#FF0000'::character varying NOT NULL,
    text_color character varying(7) DEFAULT '#FFFFFF'::character varying NOT NULL
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
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    login character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    crypted_password character varying(40),
    salt character varying(40),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    remember_token character varying(255),
    remember_token_expires_at timestamp without time zone,
    firstname character varying(255),
    lastname character varying(255),
    locale character varying(3) DEFAULT 'en'::character varying NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: workcamp_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workcamp_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workcamp_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workcamp_assignments_id_seq OWNED BY workcamp_assignments.id;


--
-- Name: workcamp_intentions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workcamp_intentions (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    description_cs character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description_en character varying(255)
);


--
-- Name: workcamp_intentions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workcamp_intentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workcamp_intentions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workcamp_intentions_id_seq OWNED BY workcamp_intentions.id;


--
-- Name: workcamp_intentions_workcamps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workcamp_intentions_workcamps (
    workcamp_id integer,
    workcamp_intention_id integer
);


--
-- Name: workcamps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workcamps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workcamps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workcamps_id_seq OWNED BY workcamps.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY apply_forms ALTER COLUMN id SET DEFAULT nextval('apply_forms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bookings ALTER COLUMN id SET DEFAULT nextval('bookings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY countries ALTER COLUMN id SET DEFAULT nextval('countries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_contacts ALTER COLUMN id SET DEFAULT nextval('email_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_templates ALTER COLUMN id SET DEFAULT nextval('email_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hostings ALTER COLUMN id SET DEFAULT nextval('hostings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_changes ALTER COLUMN id SET DEFAULT nextval('import_changes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY infosheets ALTER COLUMN id SET DEFAULT nextval('infosheets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY languages ALTER COLUMN id SET DEFAULT nextval('languages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY leaderships ALTER COLUMN id SET DEFAULT nextval('leaderships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY networks ALTER COLUMN id SET DEFAULT nextval('networks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations ALTER COLUMN id SET DEFAULT nextval('organizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY partners ALTER COLUMN id SET DEFAULT nextval('partners_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY partnerships ALTER COLUMN id SET DEFAULT nextval('partnerships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY payments ALTER COLUMN id SET DEFAULT nextval('payments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY people ALTER COLUMN id SET DEFAULT nextval('people_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


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

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workcamp_assignments ALTER COLUMN id SET DEFAULT nextval('workcamp_assignments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workcamp_intentions ALTER COLUMN id SET DEFAULT nextval('workcamp_intentions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workcamps ALTER COLUMN id SET DEFAULT nextval('workcamps_id_seq'::regclass);


--
-- Name: apply_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY apply_forms
    ADD CONSTRAINT apply_forms_pkey PRIMARY KEY (id);


--
-- Name: bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: email_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY email_contacts
    ADD CONSTRAINT email_contacts_pkey PRIMARY KEY (id);


--
-- Name: email_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);


--
-- Name: hostings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY hostings
    ADD CONSTRAINT hostings_pkey PRIMARY KEY (id);


--
-- Name: import_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY import_changes
    ADD CONSTRAINT import_changes_pkey PRIMARY KEY (id);


--
-- Name: infosheets_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY infosheets
    ADD CONSTRAINT infosheets_pkey PRIMARY KEY (id);


--
-- Name: languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- Name: leaderships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY leaderships
    ADD CONSTRAINT leaderships_pkey PRIMARY KEY (id);


--
-- Name: networks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY networks
    ADD CONSTRAINT networks_pkey PRIMARY KEY (id);


--
-- Name: organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: partners_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY partners
    ADD CONSTRAINT partners_pkey PRIMARY KEY (id);


--
-- Name: partnerships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY partnerships
    ADD CONSTRAINT partnerships_pkey PRIMARY KEY (id);


--
-- Name: payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: people_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


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
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: workcamp_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workcamp_assignments
    ADD CONSTRAINT workcamp_assignments_pkey PRIMARY KEY (id);


--
-- Name: workcamp_intentions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workcamp_intentions
    ADD CONSTRAINT workcamp_intentions_pkey PRIMARY KEY (id);


--
-- Name: workcamps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workcamps
    ADD CONSTRAINT workcamps_pkey PRIMARY KEY (id);


--
-- Name: fk_comments_user; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fk_comments_user ON comments USING btree (user_id);


--
-- Name: index_apply_forms_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_apply_forms_on_id ON apply_forms USING btree (id);


--
-- Name: index_infosheets_on_workcamp_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_infosheets_on_workcamp_id ON infosheets USING btree (workcamp_id);


--
-- Name: index_organizations_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organizations_on_id ON organizations USING btree (id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_taggings_on_tag_id ON taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable_id_and_taggable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_taggings_on_taggable_id_and_taggable_type ON taggings USING btree (taggable_id, taggable_type);


--
-- Name: index_volunteers_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_volunteers_on_id ON people USING btree (id);


--
-- Name: index_workcamp_assignments_on_accepted; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamp_assignments_on_accepted ON workcamp_assignments USING btree (accepted);


--
-- Name: index_workcamp_assignments_on_apply_form_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamp_assignments_on_apply_form_id ON workcamp_assignments USING btree (apply_form_id);


--
-- Name: index_workcamp_assignments_on_asked; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamp_assignments_on_asked ON workcamp_assignments USING btree (asked);


--
-- Name: index_workcamp_assignments_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamp_assignments_on_id ON workcamp_assignments USING btree (id);


--
-- Name: index_workcamp_assignments_on_infosheeted; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamp_assignments_on_infosheeted ON workcamp_assignments USING btree (infosheeted);


--
-- Name: index_workcamp_assignments_on_rejected; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamp_assignments_on_rejected ON workcamp_assignments USING btree (rejected);


--
-- Name: index_workcamp_assignments_on_workcamp_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamp_assignments_on_workcamp_id ON workcamp_assignments USING btree (workcamp_id);


--
-- Name: index_workcamps_on_begin; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamps_on_begin ON workcamps USING btree (begin);


--
-- Name: index_workcamps_on_country_id_and_begin; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamps_on_country_id_and_begin ON workcamps USING btree (country_id, begin);


--
-- Name: index_workcamps_on_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamps_on_id ON workcamps USING btree (id);


--
-- Name: index_workcamps_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamps_on_state ON workcamps USING btree (state);


--
-- Name: index_workcamps_on_state_and_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamps_on_state_and_type ON workcamps USING btree (state, type);


--
-- Name: index_workcamps_on_state_and_type_and_begin; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamps_on_state_and_type_and_begin ON workcamps USING btree (state, type, begin);


--
-- Name: index_workcamps_on_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_workcamps_on_type ON workcamps USING btree (type);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: apply_forms_volunteer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY apply_forms
    ADD CONSTRAINT apply_forms_volunteer_id_fkey FOREIGN KEY (volunteer_id) REFERENCES people(id);


--
-- Name: bookings_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bookings
    ADD CONSTRAINT bookings_country_id_fkey FOREIGN KEY (country_id) REFERENCES countries(id);


--
-- Name: bookings_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bookings
    ADD CONSTRAINT bookings_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);


--
-- Name: bookings_workcamp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bookings
    ADD CONSTRAINT bookings_workcamp_id_fkey FOREIGN KEY (workcamp_id) REFERENCES workcamps(id);


--
-- Name: comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: email_contacts_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_contacts
    ADD CONSTRAINT email_contacts_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);


--
-- Name: hostings_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hostings
    ADD CONSTRAINT hostings_partner_id_fkey FOREIGN KEY (partner_id) REFERENCES partners(id);


--
-- Name: hostings_workcamp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hostings
    ADD CONSTRAINT hostings_workcamp_id_fkey FOREIGN KEY (workcamp_id) REFERENCES workcamps(id);


--
-- Name: import_changes_workcamp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_changes
    ADD CONSTRAINT import_changes_workcamp_id_fkey FOREIGN KEY (workcamp_id) REFERENCES workcamps(id);


--
-- Name: infosheets_workcamp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY infosheets
    ADD CONSTRAINT infosheets_workcamp_id_fkey FOREIGN KEY (workcamp_id) REFERENCES workcamps(id);


--
-- Name: leaderships_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY leaderships
    ADD CONSTRAINT leaderships_person_id_fkey FOREIGN KEY (person_id) REFERENCES people(id);


--
-- Name: leaderships_workcamp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY leaderships
    ADD CONSTRAINT leaderships_workcamp_id_fkey FOREIGN KEY (workcamp_id) REFERENCES workcamps(id);


--
-- Name: organizations_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organizations_country_id_fkey FOREIGN KEY (country_id) REFERENCES countries(id);


--
-- Name: partnerships_network_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY partnerships
    ADD CONSTRAINT partnerships_network_id_fkey FOREIGN KEY (network_id) REFERENCES networks(id);


--
-- Name: partnerships_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY partnerships
    ADD CONSTRAINT partnerships_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);


--
-- Name: payments_apply_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY payments
    ADD CONSTRAINT payments_apply_form_id_fkey FOREIGN KEY (apply_form_id) REFERENCES apply_forms(id);


--
-- Name: people_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_country_id_fkey FOREIGN KEY (country_id) REFERENCES countries(id);


--
-- Name: people_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);


--
-- Name: people_workcamp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY people
    ADD CONSTRAINT people_workcamp_id_fkey FOREIGN KEY (workcamp_id) REFERENCES workcamps(id);


--
-- Name: taggings_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT taggings_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES tags(id);


--
-- Name: workcamp_assignments_apply_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workcamp_assignments
    ADD CONSTRAINT workcamp_assignments_apply_form_id_fkey FOREIGN KEY (apply_form_id) REFERENCES apply_forms(id);


--
-- Name: workcamp_assignments_workcamp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workcamp_assignments
    ADD CONSTRAINT workcamp_assignments_workcamp_id_fkey FOREIGN KEY (workcamp_id) REFERENCES workcamps(id);


--
-- Name: workcamp_intentions_workcamps_workcamp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workcamp_intentions_workcamps
    ADD CONSTRAINT workcamp_intentions_workcamps_workcamp_id_fkey FOREIGN KEY (workcamp_id) REFERENCES workcamps(id);


--
-- Name: workcamp_intentions_workcamps_workcamp_intention_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workcamp_intentions_workcamps
    ADD CONSTRAINT workcamp_intentions_workcamps_workcamp_intention_id_fkey FOREIGN KEY (workcamp_intention_id) REFERENCES workcamp_intentions(id);


--
-- Name: workcamps_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workcamps
    ADD CONSTRAINT workcamps_country_id_fkey FOREIGN KEY (country_id) REFERENCES countries(id);


--
-- Name: workcamps_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workcamps
    ADD CONSTRAINT workcamps_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20100204103640');

INSERT INTO schema_migrations (version) VALUES ('20100204103623');

INSERT INTO schema_migrations (version) VALUES ('20090325215842');

INSERT INTO schema_migrations (version) VALUES ('20100204103630');

INSERT INTO schema_migrations (version) VALUES ('20100204103628');

INSERT INTO schema_migrations (version) VALUES ('20090202111348');

INSERT INTO schema_migrations (version) VALUES ('20100204103614');

INSERT INTO schema_migrations (version) VALUES ('20100204103634');

INSERT INTO schema_migrations (version) VALUES ('20090304200627');

INSERT INTO schema_migrations (version) VALUES ('20100204103617');

INSERT INTO schema_migrations (version) VALUES ('20090418204625');

INSERT INTO schema_migrations (version) VALUES ('20100115195634');

INSERT INTO schema_migrations (version) VALUES ('20090214125124');

INSERT INTO schema_migrations (version) VALUES ('20090116152151');

INSERT INTO schema_migrations (version) VALUES ('20091123231403');

INSERT INTO schema_migrations (version) VALUES ('20081205150124');

INSERT INTO schema_migrations (version) VALUES ('20081205150155');

INSERT INTO schema_migrations (version) VALUES ('20100204103627');

INSERT INTO schema_migrations (version) VALUES ('20081205143817');

INSERT INTO schema_migrations (version) VALUES ('20100204103606');

INSERT INTO schema_migrations (version) VALUES ('20071205150145');

INSERT INTO schema_migrations (version) VALUES ('20071208141431');

INSERT INTO schema_migrations (version) VALUES ('20090313172521');

INSERT INTO schema_migrations (version) VALUES ('20081225172253');

INSERT INTO schema_migrations (version) VALUES ('20100127105330');

INSERT INTO schema_migrations (version) VALUES ('20081226131334');

INSERT INTO schema_migrations (version) VALUES ('20090422110207');

INSERT INTO schema_migrations (version) VALUES ('20090119155213');

INSERT INTO schema_migrations (version) VALUES ('20090318030055');

INSERT INTO schema_migrations (version) VALUES ('20100204103618');

INSERT INTO schema_migrations (version) VALUES ('20090215223615');

INSERT INTO schema_migrations (version) VALUES ('20100204103620');

INSERT INTO schema_migrations (version) VALUES ('20100204103631');

INSERT INTO schema_migrations (version) VALUES ('20091221113852');

INSERT INTO schema_migrations (version) VALUES ('20081202192410');

INSERT INTO schema_migrations (version) VALUES ('20100204103621');

INSERT INTO schema_migrations (version) VALUES ('20090318095819');

INSERT INTO schema_migrations (version) VALUES ('20100204103632');

INSERT INTO schema_migrations (version) VALUES ('20071205150230');

INSERT INTO schema_migrations (version) VALUES ('20081211185010');

INSERT INTO schema_migrations (version) VALUES ('20090214125123');

INSERT INTO schema_migrations (version) VALUES ('20091123140859');

INSERT INTO schema_migrations (version) VALUES ('20090105105415');

INSERT INTO schema_migrations (version) VALUES ('20090120111217');

INSERT INTO schema_migrations (version) VALUES ('20100204103629');

INSERT INTO schema_migrations (version) VALUES ('20100204103635');

INSERT INTO schema_migrations (version) VALUES ('20100204103625');

INSERT INTO schema_migrations (version) VALUES ('20100204103613');

INSERT INTO schema_migrations (version) VALUES ('20081226210600');

INSERT INTO schema_migrations (version) VALUES ('20100204103612');

INSERT INTO schema_migrations (version) VALUES ('20100204103615');

INSERT INTO schema_migrations (version) VALUES ('20090322182558');

INSERT INTO schema_migrations (version) VALUES ('20100204103616');

INSERT INTO schema_migrations (version) VALUES ('20100204103607');

INSERT INTO schema_migrations (version) VALUES ('20090105105733');

INSERT INTO schema_migrations (version) VALUES ('20100204103637');

INSERT INTO schema_migrations (version) VALUES ('20100204103611');

INSERT INTO schema_migrations (version) VALUES ('20091222102642');

INSERT INTO schema_migrations (version) VALUES ('20100204103610');

INSERT INTO schema_migrations (version) VALUES ('20090105105533');

INSERT INTO schema_migrations (version) VALUES ('20100204103638');

INSERT INTO schema_migrations (version) VALUES ('20100204103622');

INSERT INTO schema_migrations (version) VALUES ('20100204103636');

INSERT INTO schema_migrations (version) VALUES ('20081226210601');

INSERT INTO schema_migrations (version) VALUES ('20100204103639');

INSERT INTO schema_migrations (version) VALUES ('20100127105329');

INSERT INTO schema_migrations (version) VALUES ('20100204103609');

INSERT INTO schema_migrations (version) VALUES ('20100204103626');

INSERT INTO schema_migrations (version) VALUES ('20090317213853');

INSERT INTO schema_migrations (version) VALUES ('20100204103619');

INSERT INTO schema_migrations (version) VALUES ('20100204103604');

INSERT INTO schema_migrations (version) VALUES ('20100204103633');