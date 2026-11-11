export function Doc({ title, lead, children }: { title: string; lead: string; children: React.ReactNode }) {
  return (
    <article className="mx-auto max-w-3xl px-5 pt-12 sm:px-8 sm:pt-16">
      <h1 className="text-[clamp(2.5rem,7vw,3.75rem)] font-black leading-none tracking-[-0.035em]">{title}</h1>
      <p className="mt-5 max-w-[46ch] text-[clamp(1.1rem,2.2vw,1.3rem)] font-medium leading-snug text-ink-muted text-pretty">
        {lead}
      </p>
      <div className="mt-10 flex flex-col gap-3">{children}</div>
    </article>
  );
}

export function DocSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="rounded-card bg-card px-6 py-7 shadow-card sm:px-8">
      <h2 className="text-[21px] font-extrabold tracking-tight">{title}</h2>
      <div className="mt-3 flex flex-col gap-3 text-[16.5px] font-medium leading-relaxed text-ink-muted text-pretty [&_a]:font-semibold [&_a]:text-ink [&_a]:underline [&_a]:decoration-ink-faint [&_a]:underline-offset-4 [&_strong]:font-bold [&_strong]:text-ink">
        {children}
      </div>
    </section>
  );
}
