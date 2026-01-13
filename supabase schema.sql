-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.admin_audit_log (
  id bigint NOT NULL DEFAULT nextval('admin_audit_log_id_seq'::regclass),
  admin_id uuid NOT NULL,
  action text NOT NULL,
  target_table text NOT NULL,
  target_id text,
  old_value jsonb,
  new_value jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT admin_audit_log_pkey PRIMARY KEY (id),
  CONSTRAINT admin_audit_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES auth.users(id)
);
CREATE TABLE public.admin_directory (
  id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT admin_directory_pkey PRIMARY KEY (id),
  CONSTRAINT admin_directory_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.appointments (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  doctor_id uuid,
  pet_id uuid,
  date date NOT NULL,
  time text NOT NULL,
  type text,
  status text DEFAULT 'pending'::text,
  created_at timestamp with time zone DEFAULT now(),
  price integer DEFAULT 0,
  CONSTRAINT appointments_pkey PRIMARY KEY (id),
  CONSTRAINT appointments_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id),
  CONSTRAINT appointments_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id),
  CONSTRAINT appointments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.availability_slots (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  doctor_id uuid,
  day text NOT NULL,
  start_time text NOT NULL,
  end_time text NOT NULL,
  CONSTRAINT availability_slots_pkey PRIMARY KEY (id),
  CONSTRAINT availability_slots_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.doctors(id)
);
CREATE TABLE public.chat_participants (
  id integer NOT NULL DEFAULT nextval('chat_participants_id_seq'::regclass),
  chat_id integer NOT NULL,
  user_id uuid NOT NULL,
  joined_at timestamp with time zone DEFAULT now(),
  CONSTRAINT chat_participants_pkey PRIMARY KEY (id),
  CONSTRAINT chat_participants_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES public.chats(id),
  CONSTRAINT chat_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.chats (
  id integer NOT NULL DEFAULT nextval('chats_id_seq'::regclass),
  type text NOT NULL DEFAULT 'private'::text,
  name text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT chats_pkey PRIMARY KEY (id)
);
CREATE TABLE public.comment_likes (
  user_id uuid NOT NULL,
  comment_id bigint NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT comment_likes_pkey PRIMARY KEY (user_id, comment_id),
  CONSTRAINT comment_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT comment_likes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.post_comments(id)
);
CREATE TABLE public.doctor_applications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  specialty text NOT NULL,
  clinic_name text NOT NULL,
  license_number text,
  years_experience integer,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])),
  submitted_at timestamp with time zone DEFAULT now(),
  reviewed_at timestamp with time zone,
  reviewed_by uuid,
  rejection_reason text,
  CONSTRAINT doctor_applications_pkey PRIMARY KEY (id),
  CONSTRAINT doctor_applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT doctor_applications_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id)
);
CREATE TABLE public.doctors (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  specialty text,
  clinic text,
  rating numeric DEFAULT 0,
  reviews_count integer DEFAULT 0,
  available boolean DEFAULT true,
  next_available text,
  verified boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  rejection_reason text,
  verified_at timestamp with time zone,
  verified_by uuid,
  CONSTRAINT doctors_pkey PRIMARY KEY (id),
  CONSTRAINT doctors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.friendships (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  requester_id uuid NOT NULL,
  receiver_id uuid NOT NULL,
  status text NOT NULL CHECK (status = ANY (ARRAY['pending'::text, 'accepted'::text, 'blocked'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT friendships_pkey PRIMARY KEY (id),
  CONSTRAINT friendships_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES auth.users(id),
  CONSTRAINT friendships_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES auth.users(id)
);
CREATE TABLE public.messages (
  id integer NOT NULL DEFAULT nextval('messages_id_seq'::regclass),
  chat_id integer NOT NULL,
  sender_id uuid NOT NULL,
  content text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  edited_at timestamp with time zone,
  updated_at timestamp with time zone DEFAULT now(),
  deleted_at timestamp with time zone,
  client_message_id uuid,
  status text DEFAULT 'sent'::text CHECK (status = ANY (ARRAY['pending'::text, 'sent'::text, 'delivered'::text, 'read'::text, 'failed'::text])),
  delivered_at timestamp with time zone,
  read_at timestamp with time zone,
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES public.chats(id),
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id)
);
CREATE TABLE public.notification_preferences (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL UNIQUE,
  enable_messages boolean DEFAULT true,
  enable_appointments boolean DEFAULT true,
  enable_community boolean DEFAULT true,
  enable_reminders boolean DEFAULT true,
  enable_quiet_hours boolean DEFAULT false,
  quiet_hours_start time without time zone DEFAULT '22:00:00'::time without time zone,
  quiet_hours_end time without time zone DEFAULT '08:00:00'::time without time zone,
  enable_sound boolean DEFAULT true,
  enable_vibration boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notification_preferences_pkey PRIMARY KEY (id),
  CONSTRAINT notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.notifications (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL,
  actor_id uuid,
  type text NOT NULL CHECK (type = ANY (ARRAY['message'::text, 'appointment_accepted'::text, 'appointment_rejected'::text, 'appointment_rescheduled'::text, 'appointment_reminder'::text, 'appointment_request'::text, 'appointment_cancelled'::text, 'community_like'::text, 'community_comment'::text, 'follow'::text, 'friend_request'::text])),
  title text NOT NULL,
  body text NOT NULL,
  related_id uuid,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES auth.users(id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.pet_health_events (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  pet_id uuid NOT NULL,
  title text NOT NULL,
  date date NOT NULL,
  type text NOT NULL,
  notes text,
  CONSTRAINT pet_health_events_pkey PRIMARY KEY (id),
  CONSTRAINT pet_health_events_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id)
);
CREATE TABLE public.pets (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  owner_id uuid,
  name text NOT NULL,
  type text,
  breed text,
  age text,
  health text,
  emoji text DEFAULT '🐾'::text,
  image_url text,
  next_checkup date,
  created_at timestamp with time zone DEFAULT now(),
  gender text DEFAULT 'Unknown'::text,
  weight text,
  height text,
  CONSTRAINT pets_pkey PRIMARY KEY (id),
  CONSTRAINT pets_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id)
);
CREATE TABLE public.post_comments (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL,
  post_id bigint NOT NULL,
  content text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  likes_count bigint DEFAULT 0,
  CONSTRAINT post_comments_pkey PRIMARY KEY (id),
  CONSTRAINT post_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT post_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id)
);
CREATE TABLE public.post_likes (
  user_id uuid NOT NULL,
  post_id bigint NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT post_likes_pkey PRIMARY KEY (user_id, post_id),
  CONSTRAINT post_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT post_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id)
);
CREATE TABLE public.posts (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  user_id uuid NOT NULL,
  content text NOT NULL,
  image_url text,
  likes_count integer DEFAULT 0,
  comments_count integer DEFAULT 0,
  tags ARRAY DEFAULT ARRAY[]::text[],
  author_name text,
  author_image text,
  location text,
  is_flagged boolean DEFAULT false,
  flagged_at timestamp with time zone,
  flagged_reason text,
  moderated_by uuid,
  CONSTRAINT posts_pkey PRIMARY KEY (id),
  CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT posts_moderated_by_fkey FOREIGN KEY (moderated_by) REFERENCES auth.users(id)
);
CREATE TABLE public.reviews (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  doctor_id uuid NOT NULL,
  user_id uuid NOT NULL,
  rating numeric NOT NULL CHECK (rating >= 1::numeric AND rating <= 5::numeric),
  comment text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT reviews_pkey PRIMARY KEY (id),
  CONSTRAINT reviews_doctor_id_fkey FOREIGN KEY (doctor_id) REFERENCES public.users(id),
  CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  email text NOT NULL UNIQUE,
  name text,
  phone text,
  role text DEFAULT 'pet_owner'::text CHECK (role = ANY (ARRAY['pet_owner'::text, 'doctor'::text, 'admin'::text, 'super_admin'::text])),
  profile_image text,
  specialty text,
  clinic text,
  bio text,
  created_at timestamp with time zone DEFAULT now(),
  username text UNIQUE,
  rating numeric DEFAULT NULL::numeric,
  reviews_count integer DEFAULT 0,
  banned_at timestamp with time zone,
  banned_reason text,
  banned_by uuid,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_banned_by_fkey FOREIGN KEY (banned_by) REFERENCES auth.users(id)
);

-- ============================================================================
-- SECURE ACCOUNT DELETION RPC
-- ============================================================================
-- CREATE OR REPLACE FUNCTION public.delete_own_account()
-- RETURNS json
-- LANGUAGE plpgsql
-- SECURITY DEFINER
-- SET search_path = public, auth
-- AS $$
-- DECLARE v_user_id uuid;
-- BEGIN
--   v_user_id := auth.uid();
--   IF v_user_id IS NULL THEN RETURN json_build_object('success', false, 'error', 'Not authenticated'); END IF;
--   
--   DELETE FROM public.notifications WHERE user_id = v_user_id OR actor_id = v_user_id;
--   DELETE FROM public.messages WHERE sender_id = v_user_id;
--   DELETE FROM public.chat_participants WHERE user_id = v_user_id;
--   DELETE FROM public.comment_likes WHERE user_id = v_user_id;
--   DELETE FROM public.post_likes WHERE user_id = v_user_id;
--   DELETE FROM public.post_comments WHERE user_id = v_user_id;
--   DELETE FROM public.posts WHERE user_id = v_user_id;
--   DELETE FROM public.pet_health_events WHERE pet_id IN (SELECT id FROM public.pets WHERE owner_id = v_user_id);
--   DELETE FROM public.appointments WHERE user_id = v_user_id OR pet_id IN (SELECT id FROM public.pets WHERE owner_id = v_user_id);
--   DELETE FROM public.pets WHERE owner_id = v_user_id;
--   DELETE FROM public.friendships WHERE requester_id = v_user_id OR receiver_id = v_user_id;
--   DELETE FROM public.reviews WHERE user_id = v_user_id OR doctor_id = v_user_id;
--   DELETE FROM public.availability_slots WHERE doctor_id IN (SELECT id FROM public.doctors WHERE user_id = v_user_id);
--   DELETE FROM public.doctors WHERE user_id = v_user_id;
--   DELETE FROM public.doctor_applications WHERE user_id = v_user_id;
--   DELETE FROM public.notification_preferences WHERE user_id = v_user_id;
--   DELETE FROM public.users WHERE id = v_user_id;
--   DELETE FROM auth.users WHERE id = v_user_id;
--   
--   RETURN json_build_object('success', true);
-- EXCEPTION WHEN OTHERS THEN
--   RETURN json_build_object('success', false, 'error', SQLERRM);
-- END;
-- $$;
