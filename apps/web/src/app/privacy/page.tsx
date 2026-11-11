import type { Metadata } from "next";
import { Doc, DocSection } from "@/components/Doc";
import { site } from "@/site";

export const metadata: Metadata = {
  title: "Privacy",
  description: `How ${site.name} handles your data: it stays on your iPhone, and online games go through Apple Game Center.`,
};

export default function Privacy() {
  return (
    <Doc title="Privacy" lead={`${site.name} doesn't collect your data. There is no account, no analytics, no ads and no tracking.`}>
      <DocSection title="What stays on your iPhone">
        <p>
          Your settings, games against the computer, free-play games, your day-by-day history and your Learn progress
          are saved on your iPhone, inside the app. They are never sent to us. Deleting the app deletes them.
        </p>
      </DocSection>
      <DocSection title="Online games with friends">
        <p>
          Online play uses <strong>Apple Game Center</strong>. When you are signed in to Game Center, the app uses it to
          send invites and run turn-based games. Each turn sends the moves played so far and the Game Center player ID
          of whoever plays White, so your friend&rsquo;s app can show the game.
        </p>
        <p>
          That data goes through Apple, not through us, and Apple&rsquo;s{" "}
          <a href="https://www.apple.com/legal/privacy/">privacy policy</a> applies to it. You can play every other part
          of the app without Game Center.
        </p>
      </DocSection>
      <DocSection title="Notifications">
        <p>
          If you turn on the daily reminder, iOS schedules it on your iPhone. Nothing about it leaves your device, and
          you can turn it off in the app or in Settings.
        </p>
      </DocSection>
      <DocSection title="Courses">
        <p>Learn courses ship inside the app. Opening a course doesn&rsquo;t contact lichess or anyone else.</p>
      </DocSection>
      <DocSection title="Contact">
        <p>
          Questions about privacy: <a href={`mailto:${site.email}`}>{site.email}</a>. If this policy changes, this page
          will say what changed and when.
        </p>
        <p>Last updated {site.updated}.</p>
      </DocSection>
    </Doc>
  );
}
