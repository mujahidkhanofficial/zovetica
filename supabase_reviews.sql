-- Create Reviews Table
create table if not exists public.reviews (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  doctor_id uuid references public.users(id) not null,
  user_id uuid references public.users(id) not null,
  appointment_id text not null, -- Assuming appointment IDs are text from the service/mock or specialized appointments table
  rating integer check (rating >= 1 and rating <= 5) not null,
  comment text,
  
  -- Unique constraint to prevent duplicate reviews for the same appointment
  unique(user_id, appointment_id)
);

-- RLS Policies
alter table public.reviews enable row level security;

-- Drop policies if they exist to prevent errors on re-run
drop policy if exists "Reviews are viewable by everyone" on public.reviews;
drop policy if exists "Users can insert their own reviews" on public.reviews;
drop policy if exists "Users can update their own reviews" on public.reviews;

create policy "Reviews are viewable by everyone"
  on public.reviews for select
  using ( true );

create policy "Users can insert their own reviews"
  on public.reviews for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own reviews"
  on public.reviews for update
  using ( auth.uid() = user_id );

-- RPC Function to add review and update doctor stats atomically
create or replace function add_review(
  p_doctor_id uuid,
  p_appointment_id text,
  p_rating integer,
  p_comment text default null
)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
begin
  -- Get current user ID
  v_user_id := auth.uid();
  
  -- Insert the review
  insert into public.reviews (doctor_id, user_id, appointment_id, rating, comment)
  values (p_doctor_id, v_user_id, p_appointment_id, p_rating, p_comment);

  -- Update doctor stats in users table
  -- Assuming users table has 'rating' (decimal) and 'reviews_count' (int)
  update public.users
  set 
    rating = (
      select coalesce(avg(rating), 0)
      from public.reviews
      where doctor_id = p_doctor_id
    ),
    reviews_count = (
      select count(*)
      from public.reviews
      where doctor_id = p_doctor_id
    )
  where id = p_doctor_id;
  
end;
$$;