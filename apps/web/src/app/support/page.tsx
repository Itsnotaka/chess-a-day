import type { Metadata } from "next";
import { Doc, DocSection } from "@/components/Doc";
import { site } from "@/site";

export const metadata: Metadata = {
  title: "Support",
  description: `Help with ${site.name}: joining the beta, playing friends online, reminders and levels.`,
};

export default function Support() {
  return (
    <Doc title="Support" lead="Something not working, or an idea for the app? Write any time.">
      <DocSection title="Contact">
        <p>
          Email <a href={`mailto:${site.email}?subject=${encodeURIComponent(site.name)}`}>{site.email}</a>. Say which
          iPhone and iOS version you use, and what you expected to happen.
        </p>
      </DocSection>
      <DocSection title="Joining the beta">
        <p>
          Install <a href="https://apps.apple.com/app/testflight/id899247664">TestFlight</a> from the App Store, then
          open <a href={site.betaUrl}>the beta link</a> on your iPhone and tap Install. {site.name} needs iOS 18 or
          later. If the link says the beta isn&rsquo;t accepting testers, Apple is still reviewing a build; try again later.
        </p>
      </DocSection>
      <DocSection title="Playing a friend online">
        <p>
          Sign in to Game Center in the Settings app first. Then tap <strong>Online</strong> on the home screen to invite a
          friend through Game Center, your recent players or Messages. Your friend needs the app too.
        </p>
        <p>
          Each player has 24 hours per turn. Games waiting on you show first, and the tile&rsquo;s badge counts them.
        </p>
      </DocSection>
      <DocSection title="The daily reminder doesn't arrive">
        <p>
          Check that notifications for {site.name} are allowed in Settings, under Notifications. If you said no when the
          app first asked, the reminder switch stays off until you allow them there.
        </p>
      </DocSection>
      <DocSection title="Changing the level">
        <p>
          Open settings from the home screen and choose <strong>Difficulty</strong>. The new level applies from your next
          game, so a game in progress keeps the level it started with.
        </p>
      </DocSection>
    </Doc>
  );
}
