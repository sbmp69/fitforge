export const metadata = {
  title: 'Delete Account & Data | FitForge AI',
  description: 'Request account and data deletion for FitForge AI fitness and nutrition app.',
};

export default function DeleteAccountPage() {
  return (
    <main className="min-h-screen bg-black text-slate-300 py-16 px-6 sm:px-12 lg:px-24">
      <div className="max-w-4xl mx-auto space-y-8">
        <h1 className="text-4xl md:text-5xl font-extrabold text-white mb-2">Account &amp; Data Deletion</h1>
        <p className="text-sm text-[#39FF14] uppercase tracking-widest font-semibold pb-8 border-b border-[#142419]">
          FitForge AI — User Data Control &amp; Privacy
        </p>

        <section className="space-y-4">
          <p className="text-lg text-slate-200">
            At FitForge AI, we respect your right to control your personal information. You can request the complete deletion of your account and all associated personal data at any time.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">How to Delete Your Account and Data</h2>
          <p>You have two simple ways to delete your account and associated data:</p>
          
          <div className="bg-[#0e1610] border border-[#142419] rounded-xl p-6 space-y-3">
            <h3 className="text-xl font-semibold text-[#39FF14]">Option 1: In-App Deletion (Instant)</h3>
            <ol className="list-decimal pl-6 space-y-2 text-slate-300">
              <li>Open the <strong>FitForge</strong> app on your device.</li>
              <li>Log in to your account if not already signed in.</li>
              <li>Navigate to the <strong>Profile</strong> tab from the bottom navigation bar.</li>
              <li>Scroll down to the <strong>Account Settings</strong> section.</li>
              <li>Tap <strong>Delete Account</strong> and confirm your choice.</li>
            </ol>
            <p className="text-sm text-slate-400">Your account, credentials, and personal records will be immediately queued for permanent deletion.</p>
          </div>

          <div className="bg-[#0e1610] border border-[#142419] rounded-xl p-6 space-y-3">
            <h3 className="text-xl font-semibold text-[#39FF14]">Option 2: Web / Email Request</h3>
            <p className="text-slate-300">
              If you have uninstalled the app or cannot access your account, you can submit a deletion request by email:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-slate-300">
              <li>Send an email to: <strong className="text-[#39FF14]">appfitforge@gmail.com</strong></li>
              <li>Subject line: <strong>Request Account and Data Deletion</strong></li>
              <li>Include the <strong>email address</strong> associated with your FitForge account.</li>
            </ul>
            <p className="text-sm text-slate-400">
              Our team will verify your request and permanently delete your account and data within <strong>30 days</strong>. You will receive a confirmation email once completed.
            </p>
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">Types of Data That Will Be Deleted</h2>
          <p>When your account is deleted, the following data is permanently wiped from our databases:</p>
          <ul className="list-disc pl-6 space-y-2 text-slate-300">
            <li><strong>Account Profile:</strong> Email address, user ID, full name, age, gender, height, and current weight.</li>
            <li><strong>Health &amp; Fitness Goals:</strong> Target weight, dietary preferences, fitness level, and equipment choices.</li>
            <li><strong>Generated Plans:</strong> All AI-generated workout routines and customized meal plans.</li>
            <li><strong>Activity &amp; Progress History:</strong> Logged workouts, meal consumption logs, water intake, and weight history.</li>
            <li><strong>Progress Photos:</strong> Any photos uploaded for personal tracking are permanently deleted from secure cloud storage.</li>
            <li><strong>AI Conversation Transcripts:</strong> All chat messages and coaching history with the AI Coach.</li>
          </ul>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-bold text-white">Data Retention Policy</h2>
          <p className="text-slate-300">
            We retain your data only for as long as your account remains active. When an account deletion is requested:
          </p>
          <ul className="list-disc pl-6 space-y-2 text-slate-300">
            <li>Personal data and progress records are deleted from active databases within <strong>30 days</strong>.</li>
            <li>Any active subscriptions must be cancelled through your <strong>Google Play</strong> or <strong>Apple App Store</strong> account settings, as payment providers manage billing independently.</li>
            <li>Minimal anonymized transactional records may be retained only where strictly required by applicable financial and tax laws.</li>
          </ul>
        </section>

        <section className="space-y-4 pb-12">
          <h2 className="text-2xl font-bold text-white">Need Assistance?</h2>
          <p className="text-slate-300">
            If you have any questions or require help with deleting your account, contact our support team at:{" "}
            <a href="mailto:appfitforge@gmail.com" className="text-[#39FF14] underline font-semibold">
              appfitforge@gmail.com
            </a>
          </p>
        </section>
      </div>
    </main>
  );
}
