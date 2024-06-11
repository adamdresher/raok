--
-- PostgreSQL database dump
--

-- Dumped from database version 14.12 (Homebrew)
-- Dumped by pg_dump version 14.12 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: asdresher
--

CREATE TABLE public.comments (
    id integer NOT NULL,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    description character varying NOT NULL,
    commented_on timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.comments OWNER TO asdresher;

--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: asdresher
--

CREATE SEQUENCE public.comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_id_seq OWNER TO asdresher;

--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asdresher
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: favorites; Type: TABLE; Schema: public; Owner: asdresher
--

CREATE TABLE public.favorites (
    id integer NOT NULL,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    favorited_on timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.favorites OWNER TO asdresher;

--
-- Name: favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: asdresher
--

CREATE SEQUENCE public.favorites_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.favorites_id_seq OWNER TO asdresher;

--
-- Name: favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asdresher
--

ALTER SEQUENCE public.favorites_id_seq OWNED BY public.favorites.id;


--
-- Name: hashtag_list; Type: TABLE; Schema: public; Owner: asdresher
--

CREATE TABLE public.hashtag_list (
    id integer NOT NULL,
    title character varying(50) NOT NULL
);


ALTER TABLE public.hashtag_list OWNER TO asdresher;

--
-- Name: hashtag_list_id_seq; Type: SEQUENCE; Schema: public; Owner: asdresher
--

CREATE SEQUENCE public.hashtag_list_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hashtag_list_id_seq OWNER TO asdresher;

--
-- Name: hashtag_list_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asdresher
--

ALTER SEQUENCE public.hashtag_list_id_seq OWNED BY public.hashtag_list.id;


--
-- Name: hashtags; Type: TABLE; Schema: public; Owner: asdresher
--

CREATE TABLE public.hashtags (
    id integer NOT NULL,
    hashtag_id integer NOT NULL,
    post_id integer NOT NULL
);


ALTER TABLE public.hashtags OWNER TO asdresher;

--
-- Name: hashtags_id_seq; Type: SEQUENCE; Schema: public; Owner: asdresher
--

CREATE SEQUENCE public.hashtags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hashtags_id_seq OWNER TO asdresher;

--
-- Name: hashtags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asdresher
--

ALTER SEQUENCE public.hashtags_id_seq OWNED BY public.hashtags.id;


--
-- Name: likes; Type: TABLE; Schema: public; Owner: asdresher
--

CREATE TABLE public.likes (
    id integer NOT NULL,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    liked_on timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.likes OWNER TO asdresher;

--
-- Name: likes_id_seq; Type: SEQUENCE; Schema: public; Owner: asdresher
--

CREATE SEQUENCE public.likes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.likes_id_seq OWNER TO asdresher;

--
-- Name: likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asdresher
--

ALTER SEQUENCE public.likes_id_seq OWNED BY public.likes.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: asdresher
--

CREATE TABLE public.posts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_on timestamp with time zone DEFAULT now() NOT NULL,
    public boolean DEFAULT true NOT NULL,
    description character varying DEFAULT ''::character varying
);


ALTER TABLE public.posts OWNER TO asdresher;

--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: asdresher
--

CREATE SEQUENCE public.posts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.posts_id_seq OWNER TO asdresher;

--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asdresher
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: asdresher
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    email character varying(50) NOT NULL,
    username character varying(50) NOT NULL,
    created_on timestamp with time zone DEFAULT now() NOT NULL,
    last_login timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO asdresher;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: asdresher
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO asdresher;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: asdresher
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: favorites id; Type: DEFAULT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.favorites ALTER COLUMN id SET DEFAULT nextval('public.favorites_id_seq'::regclass);


--
-- Name: hashtag_list id; Type: DEFAULT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.hashtag_list ALTER COLUMN id SET DEFAULT nextval('public.hashtag_list_id_seq'::regclass);


--
-- Name: hashtags id; Type: DEFAULT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.hashtags ALTER COLUMN id SET DEFAULT nextval('public.hashtags_id_seq'::regclass);


--
-- Name: likes id; Type: DEFAULT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.likes ALTER COLUMN id SET DEFAULT nextval('public.likes_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (id);


--
-- Name: hashtag_list hashtag_list_pkey; Type: CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.hashtag_list
    ADD CONSTRAINT hashtag_list_pkey PRIMARY KEY (id);


--
-- Name: hashtags hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.hashtags
    ADD CONSTRAINT hashtags_pkey PRIMARY KEY (id);


--
-- Name: likes likes_pkey; Type: CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: comments comments_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: comments comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: favorites favorites_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: favorites favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: hashtags hashtags_hashtag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.hashtags
    ADD CONSTRAINT hashtags_hashtag_id_fkey FOREIGN KEY (hashtag_id) REFERENCES public.hashtag_list(id) ON DELETE CASCADE;


--
-- Name: hashtags hashtags_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.hashtags
    ADD CONSTRAINT hashtags_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: likes likes_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: likes likes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: posts posts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: asdresher
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

