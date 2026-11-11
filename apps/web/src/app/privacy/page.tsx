import type { Metadata } from "next";
import { Doc, DocSection } from "@/components/Doc";
import { site } from "@/site";

export const metadata: Metadata = {
  title: "Privacy",
  description: `${site.name} collects no data. Games stay on your iPhone; online games go through Apple Game Center.`,
};

export default function Privacy() {
  return (
    <Doc title="Privacy" lead={`${site.name} collects no data. No account, analytics, ads or tracking.`}>
      <DocSection title="On your iPhone">
        <p>
          Settings, games, your day-by-day history and Learn progress are saved in the app and never sent to us.
          Deleting the app deletes them.
        </p>
      </DocSection>
      <DocSection title="Online games">
        <p>
          Online play runs on <strong>Apple Game Center</strong>. Each turn sends the moves so far and the Game Center
          player ID of whoever plays White, so your friend&rsquo;s app can show the game.
        </p>
        <p>
          That goes through Apple, not us, under Apple&rsquo;s{" "}
          <a href="https://www.apple.com/legal/privacy/">privacy policy</a>. Everything else works without Game Center.
        </p>
      </DocSection>
      <DocSection title="Daily reminder">
        <p>iOS schedules the reminder on your iPhone. Nothing about it leaves the device.</p>
      </DocSection>
      <DocSection title="Courses">
        <p>Courses ship inside the app. Opening one contacts no one, lichess included.</p>
      </DocSection>
      <DocSection title="Questions">
        <p>
          Email <a href={`mailto:${site.email}`}>{site.email}</a>. If this policy changes, this page will say what
          changed and when. Last updated {site.updated}.
        </p>
      </DocSection>
    </Doc>
  );
}
