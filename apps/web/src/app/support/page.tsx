import type { Metadata } from "next";
import { EmailPill } from "@/components/Chrome";
import { Doc, Questions } from "@/components/Doc";
import { site } from "@/site";

export const metadata: Metadata = {
  title: "Support",
  description: `Help with ${site.name}: joining the beta, playing friends online, reminders and levels.`,
};

const questions = [
  {
    question: "How do I join the beta?",
    answer: (
      <p>
        Install <a href="https://apps.apple.com/app/testflight/id899247664">TestFlight</a>, then open{" "}
        <a href={site.betaUrl}>the beta link</a> on your iPhone and tap Install. You need iOS 18 or later. If the link
        says the beta isn&rsquo;t accepting testers, Apple is reviewing a new build. Try again in a day.
      </p>
    ),
  },
  {
    question: "How do I play a friend online?",
    answer: (
      <p>
        Sign in to Game Center in the Settings app, then tap <strong>Online</strong> on the home screen. Your friend
        needs the app too. Each turn has 24 hours.
      </p>
    ),
  },
  {
    question: "Why doesn\u2019t my daily reminder arrive?",
    answer: (
      <p>
        Allow notifications for {site.name} in Settings, under Notifications. If you said no when the app asked, the
        reminder stays off until you do.
      </p>
    ),
  },
  {
    question: "How do I change the level?",
    answer: (
      <p>
        Open settings from the home screen and tap <strong>Difficulty</strong>. The new level starts with your next
        game.
      </p>
    ),
  },
];

export default function Support() {
  return (
    <Doc
      title="Support"
      lead="Something broken, or an idea? Say which iPhone and iOS version you use."
      action={<EmailPill subject={site.name} />}
    >
      <Questions items={questions} />
    </Doc>
  );
}
