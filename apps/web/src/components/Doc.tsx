import { Accordion } from "@base-ui/react/accordion";

const prose =
  "flex flex-col gap-3 text-body font-medium text-ink-muted text-pretty [&_a]:font-semibold [&_a]:text-ink [&_a]:underline [&_a]:decoration-ink-faint [&_a]:underline-offset-4 [&_a:hover]:decoration-ink [&_strong]:font-bold [&_strong]:text-ink";

export function Doc({
  title,
  lead,
  action,
  children,
}: {
  title: string;
  lead: React.ReactNode;
  action?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <article className="mx-auto max-w-3xl px-5 pt-10 sm:px-8 sm:pt-16">
      <h1 className="text-display font-bold">{title}</h1>
      <p className="mt-5 max-w-[40ch] text-lead font-medium text-pretty text-ink-muted">{lead}</p>
      {action && <div className="mt-8">{action}</div>}
      <div className="mt-10 divide-y divide-hairline overflow-hidden rounded-card bg-card shadow-card">{children}</div>
    </article>
  );
}

export function DocSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="px-6 py-6 sm:px-8 sm:py-7">
      <h2 className="text-heading font-extrabold">{title}</h2>
      <div className={`mt-2 ${prose}`}>{children}</div>
    </section>
  );
}

/** Questions that open in place. Closed answers stay in the page, so find-in-page and search still reach them. */
export function Questions({ items }: { items: { question: string; answer: React.ReactNode }[] }) {
  return (
    <Accordion.Root hiddenUntilFound className="divide-y divide-hairline">
      {items.map((item) => (
        <Accordion.Item key={item.question}>
          <Accordion.Header className="m-0">
            <Accordion.Trigger className="group flex min-h-11 w-full items-center justify-between gap-4 px-6 py-5 text-start text-heading font-extrabold outline-offset-[-3px] sm:px-8 sm:py-6">
              {item.question}
              <svg
                viewBox="0 0 24 24"
                aria-hidden="true"
                className="size-5 shrink-0 text-ink-muted transition-[rotate] duration-200 ease-out group-data-panel-open:rotate-45 motion-reduce:transition-none"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
              >
                <path d="M12 5v14M5 12h14" />
              </svg>
            </Accordion.Trigger>
          </Accordion.Header>
          <Accordion.Panel className="h-(--accordion-panel-height) overflow-hidden transition-[height] duration-200 ease-out data-ending-style:h-0 data-starting-style:h-0 motion-reduce:transition-none">
            <div className={`-mt-2 px-6 pb-6 sm:px-8 ${prose}`}>{item.answer}</div>
          </Accordion.Panel>
        </Accordion.Item>
      ))}
    </Accordion.Root>
  );
}
