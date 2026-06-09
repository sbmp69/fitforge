import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const formData = await request.formData();
  const file = formData.get("file") as File;
  const photoType = formData.get("type") as string;

  if (!file || !["before", "after"].includes(photoType)) {
    return NextResponse.json({ error: "Invalid upload" }, { status: 400 });
  }

  const ext = file.name.split(".").pop();
  const path = `${user.id}/${photoType}-${Date.now()}.${ext}`;

  const { error: uploadError } = await supabase.storage
    .from("progress-photos")
    .upload(path, file);

  if (uploadError) {
    return NextResponse.json({ error: uploadError.message }, { status: 500 });
  }

  const { data: photo } = await supabase
    .from("progress_photos")
    .insert({
      user_id: user.id,
      photo_type: photoType,
      storage_path: path,
    })
    .select()
    .single();

  return NextResponse.json({ photo });
}
