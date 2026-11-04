import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function POST(req: Request) {
  try {
    const { 
      email, 
      password, 
      full_name, 
      role,
      height_cm,
      weight_kg,
      primary_goal,
      fitness_level,
      country,
      meal_preference,
      date_of_birth,
      gender,
      target_focus_areas,
      body_fat_range,
      target_weight_kg,
      target_pace,
      weight_loss_history,
      lifestyle_issues,
      injuries,
      equipment,
      workout_days,
      workout_reminder,
    } = await req.json();

    if (!email || !password) {
      return NextResponse.json({ error: 'Email and password are required' }, { status: 400 });
    }

    // Initialize Supabase admin client to bypass rate limits and email confirmations
    const supabaseAdmin = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    // Create the user with admin privileges (bypasses rate limits and auto-confirms)
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: full_name || '',
        role: role || 'fitness_user',
      },
    });

    if (authError) {
      return NextResponse.json({ error: authError.message }, { status: 400 });
    }

    // Insert or update profile data with onboarding information
    if (authData.user) {
      const profilePayload: Record<string, any> = {
        id: authData.user.id,
        full_name: full_name || '',
        role: role || 'fitness_user',
        updated_at: new Date().toISOString(),
      };

      if (height_cm !== undefined) profilePayload.height_cm = height_cm;
      if (weight_kg !== undefined) profilePayload.weight_kg = weight_kg;
      if (primary_goal !== undefined) profilePayload.primary_goal = primary_goal;
      if (fitness_level !== undefined) profilePayload.fitness_level = fitness_level;
      if (country !== undefined) profilePayload.country = country;
      if (meal_preference !== undefined) profilePayload.meal_preference = meal_preference;
      if (date_of_birth !== undefined) profilePayload.date_of_birth = date_of_birth;
      if (gender !== undefined) profilePayload.gender = gender;
      if (target_focus_areas !== undefined) profilePayload.target_focus_areas = target_focus_areas;
      if (body_fat_range !== undefined) profilePayload.body_fat_range = body_fat_range;
      if (target_weight_kg !== undefined) profilePayload.target_weight_kg = target_weight_kg;
      if (target_pace !== undefined) profilePayload.target_pace = target_pace;
      if (weight_loss_history !== undefined) profilePayload.weight_loss_history = weight_loss_history;
      if (lifestyle_issues !== undefined) profilePayload.lifestyle_issues = lifestyle_issues;
      if (injuries !== undefined) profilePayload.injuries = injuries;
      if (equipment !== undefined) profilePayload.equipment = equipment;
      if (workout_days !== undefined) profilePayload.workout_days = workout_days;
      if (workout_reminder !== undefined) profilePayload.workout_reminder = workout_reminder;

      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .upsert(profilePayload);

      if (profileError) {
        console.error('Profile creation error:', profileError);
      }
    }

    return NextResponse.json({ success: true, user: authData.user }, { status: 200 });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
