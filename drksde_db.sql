--
-- PostgreSQL database dump
--

\restrict wdIQLz82DX7oernB5skVyOCA9u1GKGztHdgK81OnEpPxF4TqlM18A30IyFrPbD9

-- Dumped from database version 14.20 (Homebrew)
-- Dumped by pg_dump version 14.20 (Homebrew)

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

--
-- Name: search_products(text); Type: FUNCTION; Schema: public; Owner: pablo
--

CREATE FUNCTION public.search_products(search_query text) RETURNS TABLE(product_id integer, name character varying, relevance real)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_id, p.name, 
           ts_rank(to_tsvector('english', p.name || ' ' || p.short_description), 
                   plainto_tsquery('english', search_query)) as relevance
    FROM products p
    WHERE to_tsvector('english', p.name || ' ' || p.short_description) @@ plainto_tsquery('english', search_query)
    ORDER BY relevance DESC;
END;
$$;


ALTER FUNCTION public.search_products(search_query text) OWNER TO pablo;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: pablo
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO pablo;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.addresses (
    address_id integer NOT NULL,
    user_id integer,
    name text,
    phone text,
    address_line text,
    city text,
    state text,
    pincode text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.addresses OWNER TO pablo;

--
-- Name: addresses_address_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.addresses_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.addresses_address_id_seq OWNER TO pablo;

--
-- Name: addresses_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.addresses_address_id_seq OWNED BY public.addresses.address_id;


--
-- Name: attribute_values; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.attribute_values (
    value_id integer NOT NULL,
    attribute_id integer NOT NULL,
    value character varying(100) NOT NULL,
    hex_code character varying(7),
    display_order integer
);


ALTER TABLE public.attribute_values OWNER TO pablo;

--
-- Name: attribute_values_value_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.attribute_values_value_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attribute_values_value_id_seq OWNER TO pablo;

--
-- Name: attribute_values_value_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.attribute_values_value_id_seq OWNED BY public.attribute_values.value_id;


--
-- Name: brands; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.brands (
    brand_id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(120),
    logo_url character varying(500),
    description text,
    is_active boolean DEFAULT true
);


ALTER TABLE public.brands OWNER TO pablo;

--
-- Name: brands_brand_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.brands_brand_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.brands_brand_id_seq OWNER TO pablo;

--
-- Name: brands_brand_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.brands_brand_id_seq OWNED BY public.brands.brand_id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.categories (
    category_id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(120) NOT NULL,
    parent_id integer,
    description text,
    image_url character varying(500),
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    meta_title character varying(70),
    meta_description character varying(160),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.categories OWNER TO pablo;

--
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.categories_category_id_seq OWNER TO pablo;

--
-- Name: categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.categories_category_id_seq OWNED BY public.categories.category_id;


--
-- Name: product_categories; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.product_categories (
    product_id integer NOT NULL,
    category_id integer NOT NULL,
    is_primary boolean DEFAULT false
);


ALTER TABLE public.product_categories OWNER TO pablo;

--
-- Name: category_product_counts; Type: MATERIALIZED VIEW; Schema: public; Owner: pablo
--

CREATE MATERIALIZED VIEW public.category_product_counts AS
 SELECT c.category_id,
    c.name,
    c.slug,
    count(pc.product_id) AS product_count
   FROM (public.categories c
     LEFT JOIN public.product_categories pc ON ((c.category_id = pc.category_id)))
  WHERE (c.is_active = true)
  GROUP BY c.category_id, c.name, c.slug
  WITH NO DATA;


ALTER TABLE public.category_product_counts OWNER TO pablo;

--
-- Name: inventory_logs; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.inventory_logs (
    log_id integer NOT NULL,
    product_id integer,
    variant_id integer,
    quantity_change integer NOT NULL,
    new_quantity integer NOT NULL,
    reason character varying(200),
    reference_id character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.inventory_logs OWNER TO pablo;

--
-- Name: inventory_logs_log_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.inventory_logs_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inventory_logs_log_id_seq OWNER TO pablo;

--
-- Name: inventory_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.inventory_logs_log_id_seq OWNED BY public.inventory_logs.log_id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.order_items (
    order_item_id integer NOT NULL,
    order_id integer,
    product_id integer,
    quantity integer NOT NULL,
    price numeric(10,2) NOT NULL
);


ALTER TABLE public.order_items OWNER TO pablo;

--
-- Name: order_items_order_item_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.order_items_order_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.order_items_order_item_id_seq OWNER TO pablo;

--
-- Name: order_items_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.order_items_order_item_id_seq OWNED BY public.order_items.order_item_id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.orders (
    order_id integer NOT NULL,
    user_id integer,
    total_amount numeric(10,2) NOT NULL,
    payment_method character varying(20) NOT NULL,
    payment_status character varying(20) DEFAULT 'pending'::character varying,
    order_status character varying(20) DEFAULT 'placed'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.orders OWNER TO pablo;

--
-- Name: orders_order_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.orders_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orders_order_id_seq OWNER TO pablo;

--
-- Name: orders_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.orders_order_id_seq OWNED BY public.orders.order_id;


--
-- Name: price_history; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.price_history (
    history_id integer NOT NULL,
    product_id integer NOT NULL,
    price numeric(10,2) NOT NULL,
    sale_price numeric(10,2),
    effective_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.price_history OWNER TO pablo;

--
-- Name: price_history_history_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.price_history_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.price_history_history_id_seq OWNER TO pablo;

--
-- Name: price_history_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.price_history_history_id_seq OWNED BY public.price_history.history_id;


--
-- Name: product_attributes; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.product_attributes (
    attribute_id integer NOT NULL,
    name character varying(100) NOT NULL,
    display_type character varying(20) DEFAULT 'dropdown'::character varying,
    CONSTRAINT product_attributes_display_type_check CHECK (((display_type)::text = ANY (ARRAY[('dropdown'::character varying)::text, ('swatch'::character varying)::text, ('text'::character varying)::text])))
);


ALTER TABLE public.product_attributes OWNER TO pablo;

--
-- Name: product_attributes_attribute_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.product_attributes_attribute_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_attributes_attribute_id_seq OWNER TO pablo;

--
-- Name: product_attributes_attribute_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.product_attributes_attribute_id_seq OWNED BY public.product_attributes.attribute_id;


--
-- Name: product_images; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.product_images (
    image_id integer NOT NULL,
    product_id integer NOT NULL,
    image_url character varying(500) NOT NULL,
    alt_text character varying(200),
    display_order integer DEFAULT 0,
    is_primary boolean DEFAULT false
);


ALTER TABLE public.product_images OWNER TO pablo;

--
-- Name: product_images_image_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.product_images_image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_images_image_id_seq OWNER TO pablo;

--
-- Name: product_images_image_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.product_images_image_id_seq OWNED BY public.product_images.image_id;


--
-- Name: product_variants; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.product_variants (
    variant_id integer NOT NULL,
    product_id integer NOT NULL,
    sku character varying(50),
    price_adjustment numeric(10,2) DEFAULT 0,
    stock_quantity integer DEFAULT 0,
    image_url character varying(500),
    is_default boolean DEFAULT false
);


ALTER TABLE public.product_variants OWNER TO pablo;

--
-- Name: product_variants_variant_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.product_variants_variant_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_variants_variant_id_seq OWNER TO pablo;

--
-- Name: product_variants_variant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.product_variants_variant_id_seq OWNED BY public.product_variants.variant_id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.products (
    product_id integer NOT NULL,
    sku character varying(50) NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(220) NOT NULL,
    short_description character varying(500),
    long_description text,
    base_price numeric(10,2) NOT NULL,
    sale_price numeric(10,2),
    cost_price numeric(10,2),
    brand_id integer,
    is_active boolean DEFAULT true,
    is_featured boolean DEFAULT false,
    weight numeric(8,2),
    dimensions character varying(50),
    stock_quantity integer DEFAULT 0,
    low_stock_threshold integer DEFAULT 5,
    tax_class character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.products OWNER TO pablo;

--
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.products_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.products_product_id_seq OWNER TO pablo;

--
-- Name: products_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.products_product_id_seq OWNED BY public.products.product_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    password text NOT NULL,
    role character varying(20) DEFAULT 'customer'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.users OWNER TO pablo;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: pablo
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_user_id_seq OWNER TO pablo;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pablo
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: variant_attribute_values; Type: TABLE; Schema: public; Owner: pablo
--

CREATE TABLE public.variant_attribute_values (
    variant_id integer NOT NULL,
    value_id integer NOT NULL
);


ALTER TABLE public.variant_attribute_values OWNER TO pablo;

--
-- Name: addresses address_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.addresses ALTER COLUMN address_id SET DEFAULT nextval('public.addresses_address_id_seq'::regclass);


--
-- Name: attribute_values value_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.attribute_values ALTER COLUMN value_id SET DEFAULT nextval('public.attribute_values_value_id_seq'::regclass);


--
-- Name: brands brand_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.brands ALTER COLUMN brand_id SET DEFAULT nextval('public.brands_brand_id_seq'::regclass);


--
-- Name: categories category_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.categories ALTER COLUMN category_id SET DEFAULT nextval('public.categories_category_id_seq'::regclass);


--
-- Name: inventory_logs log_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.inventory_logs ALTER COLUMN log_id SET DEFAULT nextval('public.inventory_logs_log_id_seq'::regclass);


--
-- Name: order_items order_item_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.order_items ALTER COLUMN order_item_id SET DEFAULT nextval('public.order_items_order_item_id_seq'::regclass);


--
-- Name: orders order_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.orders ALTER COLUMN order_id SET DEFAULT nextval('public.orders_order_id_seq'::regclass);


--
-- Name: price_history history_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.price_history ALTER COLUMN history_id SET DEFAULT nextval('public.price_history_history_id_seq'::regclass);


--
-- Name: product_attributes attribute_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_attributes ALTER COLUMN attribute_id SET DEFAULT nextval('public.product_attributes_attribute_id_seq'::regclass);


--
-- Name: product_images image_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_images ALTER COLUMN image_id SET DEFAULT nextval('public.product_images_image_id_seq'::regclass);


--
-- Name: product_variants variant_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_variants ALTER COLUMN variant_id SET DEFAULT nextval('public.product_variants_variant_id_seq'::regclass);


--
-- Name: products product_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.products ALTER COLUMN product_id SET DEFAULT nextval('public.products_product_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.addresses (address_id, user_id, name, phone, address_line, city, state, pincode, created_at) FROM stdin;
\.


--
-- Data for Name: attribute_values; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.attribute_values (value_id, attribute_id, value, hex_code, display_order) FROM stdin;
1	1	Black	#000000	\N
2	1	White	#FFFFFF	\N
3	2	42	\N	\N
4	2	44	\N	\N
5	1	White	#FFFFFF	\N
6	1	Black	#000000	\N
7	2	10	\N	\N
8	2	9	\N	\N
9	3	White	#FFFFFF	\N
10	3	Black	#000000	\N
11	4	10	\N	\N
12	4	9	\N	\N
13	1	S	\N	1
14	1	M	\N	2
15	1	L	\N	3
16	1	XL	\N	4
17	1	XXL	\N	5
18	2	Black	#000000	1
19	2	White	#FFFFFF	2
20	2	Blue	#0000FF	3
21	2	Red	#FF0000	4
22	2	Gray	#808080	5
23	3	128GB	\N	1
24	3	256GB	\N	2
25	3	512GB	\N	3
\.


--
-- Data for Name: brands; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.brands (brand_id, name, slug, logo_url, description, is_active) FROM stdin;
1	Nike	nike	\N	Sportswear and shoes	t
2	Apple	apple	\N	Consumer electronics	t
3	Samsung	samsung	\N	Electronics and appliances	t
4	Dell	dell	\N	Computer brand	t
5	Canon	canon	\N	Camera brand	t
6	LG	lg	\N	Electronics	t
7	Bose	bose	\N	Audio	t
8	Adidas	adidas	\N	Sportswear	t
9	Ray-Ban	rayban	\N	Eyewear	t
10	Nintendo	nintendo	\N	Gaming	t
11	Dyson	dyson	\N	Appliances	t
12	L'Oreal	loreal	\N	Beauty	t
13	Wilson	wilson	\N	Sports	t
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.categories (category_id, name, slug, parent_id, description, image_url, display_order, is_active, meta_title, meta_description, created_at) FROM stdin;
1	Electronics	electronics	\N	Electronic items	\N	1	t	\N	\N	2026-02-03 16:05:38.301769
2	Fashion	fashion	\N	Clothing and fashion	\N	2	t	\N	\N	2026-02-03 16:05:38.301769
3	Smartphones	smartphones	1	Mobile phones	\N	1	t	\N	\N	2026-02-03 16:05:44.640586
4	Shoes	shoes	2	Footwear	\N	1	t	\N	\N	2026-02-03 16:05:44.640586
6	Smartphones & Tablets	smartphones-tablets	1	Latest mobile devices and tablets	\N	1	t	\N	\N	2026-02-03 16:09:54.025403
7	Laptops & Computers	laptops-computers	1	Computers, laptops, and accessories	\N	2	t	\N	\N	2026-02-03 16:09:54.025403
8	TV & Home Theater	tv-home-theater	1	Televisions and home cinema	\N	3	t	\N	\N	2026-02-03 16:09:54.025403
9	Cameras & Photography	cameras-photography	1	Cameras and lenses	\N	4	t	\N	\N	2026-02-03 16:09:54.025403
10	Audio & Headphones	audio-headphones	1	Audio equipment	\N	5	t	\N	\N	2026-02-03 16:09:54.025403
11	Gaming	gaming	1	Games and consoles	\N	6	t	\N	\N	2026-02-03 16:09:54.025403
12	Men's Clothing	mens-clothing	2	Apparel for men	\N	1	t	\N	\N	2026-02-03 16:10:01.166881
13	Women's Clothing	womens-clothing	2	Apparel for women	\N	2	t	\N	\N	2026-02-03 16:10:01.166881
14	Shoes & Footwear	shoes-footwear	2	Footwear	\N	3	t	\N	\N	2026-02-03 16:10:01.166881
15	Accessories	fashion-accessories	2	Fashion accessories	\N	4	t	\N	\N	2026-02-03 16:10:01.166881
18	Home & Living	home-living	\N	Everything for your home and living spaces	https://example.com/images/cat-home.jpg	3	t	\N	\N	2026-02-03 16:11:39.13472
19	Beauty & Personal Care	beauty-personal-care	\N	Cosmetics, skincare, and grooming products	https://example.com/images/cat-beauty.jpg	4	t	\N	\N	2026-02-03 16:11:39.13472
20	Sports & Outdoors	sports-outdoors	\N	Sports equipment and outdoor adventure gear	https://example.com/images/cat-sports.jpg	5	t	\N	\N	2026-02-03 16:11:39.13472
\.


--
-- Data for Name: inventory_logs; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.inventory_logs (log_id, product_id, variant_id, quantity_change, new_quantity, reason, reference_id, created_at) FROM stdin;
1	1	\N	50	50	Initial stock	\N	2026-02-03 16:06:34.044576
2	2	\N	100	100	Initial stock	\N	2026-02-03 16:06:34.044576
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.order_items (order_item_id, order_id, product_id, quantity, price) FROM stdin;
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.orders (order_id, user_id, total_amount, payment_method, payment_status, order_status, created_at) FROM stdin;
\.


--
-- Data for Name: price_history; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.price_history (history_id, product_id, price, sale_price, effective_date) FROM stdin;
1	1	149999.00	139999.00	2026-02-03 16:06:29.713218
2	2	12999.00	9999.00	2026-02-03 16:06:29.713218
\.


--
-- Data for Name: product_attributes; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.product_attributes (attribute_id, name, display_type) FROM stdin;
1	Color	swatch
2	Size	dropdown
3	Color	swatch
4	Size	dropdown
5	Size	dropdown
6	Color	swatch
7	Storage Capacity	dropdown
\.


--
-- Data for Name: product_categories; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.product_categories (product_id, category_id, is_primary) FROM stdin;
3	6	t
3	1	f
4	6	t
4	1	f
\.


--
-- Data for Name: product_images; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.product_images (image_id, product_id, image_url, alt_text, display_order, is_primary) FROM stdin;
1	1	https://example.com/iphone.jpg	\N	0	t
2	2	https://example.com/nike-shoes.jpg	\N	0	t
3	3	https://example.com/images/dell-xps.jpg	\N	0	t
4	1	https://example.com/images/iphone15-front.jpg	iPhone 15 front view	1	t
5	1	https://example.com/images/iphone15-back.jpg	iPhone 15 back view	2	f
6	1	https://example.com/images/iphone15-side.jpg	iPhone 15 side view	3	f
7	2	https://example.com/images/samsung-s23-front.jpg	Samsung Galaxy S23 front	1	t
8	2	https://example.com/images/samsung-s23-back.jpg	Samsung Galaxy S23 back	2	f
9	3	https://example.com/images/dell-xps-front.jpg	Dell XPS 13 front	1	t
10	3	https://example.com/images/dell-xps-open.jpg	Dell XPS 13 open	2	f
11	4	https://example.com/images/macbook-air-front.jpg	MacBook Air front	1	t
12	4	https://example.com/images/macbook-air-side.jpg	MacBook Air side	2	f
13	28	https://example.com/images/lg-tv-front.jpg	LG OLED TV front	1	t
14	28	https://example.com/images/lg-tv-display.jpg	LG TV displaying content	2	f
\.


--
-- Data for Name: product_variants; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.product_variants (variant_id, product_id, sku, price_adjustment, stock_quantity, image_url, is_default) FROM stdin;
1	2	NK-AIR-01-BLK-42	0.00	20	\N	t
2	4	ADIDAS-UB-BLACK-9	0.00	30	\N	t
8	1	NIKE-TSHIRT-M-BLACK	0.00	50	\N	t
9	2	NIKE-TSHIRT-M-WHITE	0.00	40	\N	f
10	3	NIKE-TSHIRT-M-BLUE	0.00	30	\N	f
11	4	NIKE-TSHIRT-M-RED	0.00	25	\N	f
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.products (product_id, sku, name, slug, short_description, long_description, base_price, sale_price, cost_price, brand_id, is_active, is_featured, weight, dimensions, stock_quantity, low_stock_threshold, tax_class, created_at, updated_at) FROM stdin;
1	IP15PM	iPhone 15 Pro Max	iphone-15-pro-max	Latest Apple smartphone	\N	149999.00	139999.00	\N	2	t	f	\N	\N	50	5	\N	2026-02-03 16:05:51.164606	2026-02-03 16:05:51.164606
2	NK-AIR-01	Nike Air Zoom	nike-air-zoom	Running shoes	\N	12999.00	9999.00	\N	1	t	f	\N	\N	100	5	\N	2026-02-03 16:05:51.164606	2026-02-03 16:05:51.164606
3	DELL-XPS-13	Dell XPS 13 Laptop	dell-xps-13-laptop	Premium ultrabook	\N	1299.99	1199.99	\N	4	t	t	\N	\N	50	5	\N	2026-02-03 16:10:12.436036	2026-02-03 16:10:12.436036
4	ADIDAS-ULTRABOOST	Adidas Ultraboost Shoes	adidas-ultraboost-shoes	Running shoes	\N	180.00	160.00	\N	8	t	t	\N	\N	200	5	\N	2026-02-03 16:10:18.0645	2026-02-03 16:10:18.0645
28	IPHONE15-128GB	iPhone 15 128GB	iphone-15-128gb	The latest iPhone with Dynamic Island and 48MP camera	Experience the revolutionary iPhone 15 featuring the innovative Dynamic Island. Powered by the A16 Bionic chip, this smartphone delivers unprecedented performance. The 48MP Main camera captures unbelievable detail. The Super Retina XDR display with ProMotion provides incredibly responsive viewing. With Emergency SOS via satellite and Crash Detection, your safety is our priority.	999.00	949.00	\N	1	t	t	206.00	146.7x71.5x7.85mm	150	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
29	SAMSUNG-S23	Samsung Galaxy S23	samsung-galaxy-s23	Powerful Android smartphone with advanced camera	The Samsung Galaxy S23 features a powerful Snapdragon 8 Gen 2 processor and a stunning Dynamic AMOLED 2X display. The triple camera system includes a 50MP main sensor with advanced image processing. With all-day battery life and fast charging, stay connected throughout your day.	899.99	849.99	\N	2	t	t	168.00	146.3x70.9x7.6mm	120	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
30	MACBOOK-AIR	MacBook Air M2	macbook-air-m2	Supercharged by M2 chip for exceptional performance	The MacBook Air with M2 chip is incredibly thin and light. Featuring a stunning Liquid Retina display, up to 18 hours of battery life, and a fanless design. Perfect for productivity and creativity on the go.	1199.00	1099.00	\N	1	t	f	1.24	304.1x215x11.3mm	85	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
31	LG-OLED55	LG 55" OLED 4K Smart TV	lg-55-oled-4k-tv	OLED technology with self-lit pixels for perfect black	The LG 55" OLED TV delivers breathtaking picture quality with self-lit OLED pixels. Powered by α9 AI Processor 4K. Features Dolby Vision IQ and Dolby Atmos for immersive cinematic experiences.	1299.99	1199.99	\N	7	t	t	18000.00	1227x709x46.9mm	45	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
32	SONY-BRAVIA	Sony Bravia 65" 4K LED TV	sony-bravia-65-4k-tv	LED TV with Triluminos Pro for rich colors	Sony Bravia 65" 4K LED TV features Cognitive Processor XR that understands how humans see and hear. With Acoustic Surface Audio+ technology, the sound comes directly from the screen.	1499.99	1399.99	\N	5	t	f	22000.00	1447x830x46.9mm	30	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
33	CANON-EOS-R5	Canon EOS R5 Mirrorless Camera	canon-eos-r5-mirrorless	Full-frame mirrorless camera with 45MP sensor	The Canon EOS R5 features a 45MP full-frame CMOS sensor with DIGIC X image processor. In-body image stabilization provides up to 8 stops of shake correction. Capable of shooting 8K video and 20 fps stills.	3899.00	3699.00	\N	6	t	t	738.00	138.5x97.5x88mm	25	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
34	SONY-A7IV	Sony Alpha 7 IV Camera	sony-alpha-7-iv	33MP full-frame mirrorless camera	Sony Alpha 7 IV features a 33MP full-frame Exmor R CMOS sensor and BIONZ XR processor. Advanced Real-time Eye AF and Real-time Tracking. 4K 60p video recording with 10-bit 4:2:2 color sampling.	2499.99	2299.99	\N	5	t	t	658.00	131.3x96.4x79.8mm	35	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
35	BOSE-QC45	Bose QuietComfort 45 Headphones	bose-quietcomfort-45	Premium noise cancelling headphones	Bose QuietComfort 45 headphones offer world-class noise cancellation and audio performance. TriPort acoustic architecture delivers balanced audio. Up to 24 hours of battery life.	329.00	299.00	\N	10	t	t	238.00	180x170x75mm	150	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
36	SONY-WH1000XM5	Sony WH-1000XM5 Headphones	sony-wh1000xm5	Industry-leading noise cancellation	Sony WH-1000XM5 headphones feature Integrated Processor V1 for unprecedented noise cancellation. Newly developed 30mm drivers reproduce full range of frequencies up to 40kHz.	399.99	349.99	\N	5	t	f	250.00	207x185x80mm	120	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
37	NINTENDO-SWITCH	Nintendo Switch OLED	nintendo-switch-oled	Hybrid gaming console with OLED screen	Nintendo Switch OLED Model features a vibrant 7-inch OLED screen. The wider adjustable stand offers better stability. Includes 64GB of internal storage and enhanced audio.	349.99	329.99	\N	12	t	t	420.00	102x239x13.9mm	90	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
38	PLAYSTATION-5	PlayStation 5 Console	playstation-5-console	Next-gen gaming console with ultra-high speed SSD	PlayStation 5 features an ultra-high speed SSD, integrated I/O, and custom AMD GPU. 3D Audio technology and haptic feedback controller. Experience lightning-fast loading and immersive gameplay.	499.99	479.99	\N	5	t	t	4500.00	390x260x104mm	40	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
39	NIKE-TSHIRT-M	Nike Sportswear T-Shirt	nike-sportswear-t-shirt	Comfortable cotton t-shirt for men	Made from 100% cotton, this Nike t-shirt offers comfort and style. Features classic Nike logo on chest. Perfect for casual wear or light exercise.	29.99	24.99	\N	3	t	t	180.00	M	300	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
40	LEVIS-JEANS-32	Levi's 511 Slim Fit Jeans	levis-511-slim-fit-jeans	Classic slim fit jeans	Levi's 511 Slim Fit Jeans combine timeless style with comfort. Made from premium denim with stretch. Mid-rise waist and five-pocket styling.	79.50	69.50	\N	8	t	f	500.00	32x32	200	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
41	ZARA-DRESS	Zara Floral Midi Dress	zara-floral-midi-dress	Elegant floral dress for women	Zara floral midi dress made from lightweight viscose blend. Features V-neckline and adjustable tie straps. Perfect for summer occasions.	59.99	49.99	\N	9	t	t	350.00	S	150	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
42	ADIDAS-SPORT	Adidas Women's Sport Top	adidas-womens-sport-top	Moisture-wicking sport top	Adidas women's sport top made from moisture-wicking fabric. Features breathable mesh panels and racerback design. Perfect for workouts and athletic activities.	34.99	29.99	\N	4	t	f	150.00	M	180	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
43	NIKE-AIRMAX	Nike Air Max 270	nike-air-max-270	Comfortable sneakers with Max Air unit	Nike Air Max 270 features the tallest Max Air unit for all-day comfort. Breathable mesh upper and rubber outsole for traction. Available in multiple colors.	150.00	135.00	\N	3	t	t	320.00	9	250	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
44	APPLE-WATCH	Apple Watch Series 9	apple-watch-series-9	Advanced smartwatch with health features	Apple Watch Series 9 features temperature sensing, crash detection, and Always-On display. Track workouts, monitor heart health, and stay connected.	429.00	399.00	\N	1	t	t	42.30	45mm	180	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
45	RAYBAN-WAYFARER	Ray-Ban Wayfarer Sunglasses	ray-ban-wayfarer	Iconic sunglasses with timeless design	Ray-Ban Wayfarer Classic sunglasses feature the original shape that revolutionized eyewear. Made from high-quality materials with 100% UV protection.	155.00	139.99	\N	13	t	f	45.00	One size	120	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
46	SAMSUNG-TAB	Samsung Galaxy Tab S9	samsung-galaxy-tab-s9	Premium Android tablet with S Pen	Samsung Galaxy Tab S9 features Dynamic AMOLED 2X display, Snapdragon 8 Gen 2 processor, and included S Pen. Perfect for productivity and entertainment.	999.99	899.99	\N	2	t	t	498.00	254.3x165.8x5.9mm	75	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
47	LOGITECH-MX	Logitech MX Master 3S Mouse	logitech-mx-master-3s	Advanced wireless mouse for productivity	Logitech MX Master 3S features MagSpeed scrolling, 8K DPI sensor, and ergonomic design. Multi-device pairing and up to 70 days battery life.	99.99	89.99	\N	\N	t	f	141.00	124.9x84.3x51mm	200	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
48	JBL-SPEAKER	JBL Charge 5 Portable Speaker	jbl-charge-5-speaker	Portable Bluetooth speaker with power bank	JBL Charge 5 features powerful sound, IP67 waterproof rating, and built-in power bank. Up to 20 hours of playtime and PartyBoost for stereo pairing.	179.99	149.99	\N	\N	t	t	960.00	223x96.5x94mm	150	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
49	AMAZON-ECHO	Amazon Echo Dot 5th Gen	amazon-echo-dot-5	Smart speaker with Alexa	Amazon Echo Dot 5th Gen features improved audio quality, Alexa voice control, and smart home hub. Compact design fits anywhere in your home.	49.99	39.99	\N	\N	t	f	304.00	100x100x89mm	300	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
50	HP-PRINTER	HP Envy 6055 Printer	hp-envy-6055-printer	All-in-one wireless printer	HP Envy 6055 all-in-one printer features wireless printing, scanning, and copying. Mobile printing and automatic two-sided printing.	129.99	109.99	\N	\N	t	t	5500.00	432x304x154mm	80	5	\N	2026-02-03 16:25:02.905779	2026-02-03 16:25:02.905779
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.users (user_id, name, email, password, role, is_active, created_at, updated_at) FROM stdin;
1	Abhishek Panwar	abhishek@gmail.com	$2a$10$o3IVe/wBp5Rl5PSQ9c3vu.ccMYXFaBMksYNAswFiPIOqbLQJ354Pi	customer	t	2026-02-04 16:43:06.958	2026-02-04 16:43:06.959608
\.


--
-- Data for Name: variant_attribute_values; Type: TABLE DATA; Schema: public; Owner: pablo
--

COPY public.variant_attribute_values (variant_id, value_id) FROM stdin;
1	1
1	3
\.


--
-- Name: addresses_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.addresses_address_id_seq', 1, false);


--
-- Name: attribute_values_value_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.attribute_values_value_id_seq', 25, true);


--
-- Name: brands_brand_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.brands_brand_id_seq', 13, true);


--
-- Name: categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.categories_category_id_seq', 20, true);


--
-- Name: inventory_logs_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.inventory_logs_log_id_seq', 2, true);


--
-- Name: order_items_order_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.order_items_order_item_id_seq', 1, false);


--
-- Name: orders_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.orders_order_id_seq', 1, false);


--
-- Name: price_history_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.price_history_history_id_seq', 2, true);


--
-- Name: product_attributes_attribute_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.product_attributes_attribute_id_seq', 7, true);


--
-- Name: product_images_image_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.product_images_image_id_seq', 14, true);


--
-- Name: product_variants_variant_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.product_variants_variant_id_seq', 14, true);


--
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.products_product_id_seq', 50, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pablo
--

SELECT pg_catalog.setval('public.users_user_id_seq', 1, true);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (address_id);


--
-- Name: attribute_values attribute_values_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.attribute_values
    ADD CONSTRAINT attribute_values_pkey PRIMARY KEY (value_id);


--
-- Name: brands brands_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (brand_id);


--
-- Name: brands brands_slug_key; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_slug_key UNIQUE (slug);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- Name: categories categories_slug_key; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_slug_key UNIQUE (slug);


--
-- Name: inventory_logs inventory_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.inventory_logs
    ADD CONSTRAINT inventory_logs_pkey PRIMARY KEY (log_id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (order_item_id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- Name: price_history price_history_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.price_history
    ADD CONSTRAINT price_history_pkey PRIMARY KEY (history_id);


--
-- Name: product_attributes product_attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_attributes
    ADD CONSTRAINT product_attributes_pkey PRIMARY KEY (attribute_id);


--
-- Name: product_categories product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (product_id, category_id);


--
-- Name: product_images product_images_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_pkey PRIMARY KEY (image_id);


--
-- Name: product_variants product_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT product_variants_pkey PRIMARY KEY (variant_id);


--
-- Name: product_variants product_variants_sku_key; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT product_variants_sku_key UNIQUE (sku);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- Name: products products_sku_key; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_sku_key UNIQUE (sku);


--
-- Name: products products_slug_key; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_slug_key UNIQUE (slug);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: variant_attribute_values variant_attribute_values_pkey; Type: CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.variant_attribute_values
    ADD CONSTRAINT variant_attribute_values_pkey PRIMARY KEY (variant_id, value_id);


--
-- Name: idx_products_search; Type: INDEX; Schema: public; Owner: pablo
--

CREATE INDEX idx_products_search ON public.products USING gin (to_tsvector('english'::regconfig, (((((name)::text || ' '::text) || (short_description)::text) || ' '::text) || long_description)));


--
-- Name: products update_products_updated_at; Type: TRIGGER; Schema: public; Owner: pablo
--

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: addresses addresses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: attribute_values attribute_values_attribute_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.attribute_values
    ADD CONSTRAINT attribute_values_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES public.product_attributes(attribute_id) ON DELETE CASCADE;


--
-- Name: categories categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.categories(category_id) ON DELETE SET NULL;


--
-- Name: inventory_logs inventory_logs_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.inventory_logs
    ADD CONSTRAINT inventory_logs_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: inventory_logs inventory_logs_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.inventory_logs
    ADD CONSTRAINT inventory_logs_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(variant_id) ON DELETE CASCADE;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(order_id) ON DELETE CASCADE;


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id);


--
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: price_history price_history_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.price_history
    ADD CONSTRAINT price_history_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_categories product_categories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(category_id) ON DELETE CASCADE;


--
-- Name: product_categories product_categories_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_images product_images_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: product_variants product_variants_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.product_variants
    ADD CONSTRAINT product_variants_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: products products_brand_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(brand_id);


--
-- Name: variant_attribute_values variant_attribute_values_value_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.variant_attribute_values
    ADD CONSTRAINT variant_attribute_values_value_id_fkey FOREIGN KEY (value_id) REFERENCES public.attribute_values(value_id) ON DELETE CASCADE;


--
-- Name: variant_attribute_values variant_attribute_values_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pablo
--

ALTER TABLE ONLY public.variant_attribute_values
    ADD CONSTRAINT variant_attribute_values_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.product_variants(variant_id) ON DELETE CASCADE;


--
-- Name: category_product_counts; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: pablo
--

REFRESH MATERIALIZED VIEW public.category_product_counts;


--
-- PostgreSQL database dump complete
--

\unrestrict wdIQLz82DX7oernB5skVyOCA9u1GKGztHdgK81OnEpPxF4TqlM18A30IyFrPbD9

