# Acceptable use

This environment lets an AI model operate a real web browser. You are
responsible for what you ask it to do and for following the terms of every
site it visits.

## What the agent will not do

- No account logins. The agent refuses to type into password fields and stops
  when a page asks for a password.
- No CAPTCHA solving. The agent stops when a page shows a CAPTCHA or a human
  check.
- No paywall bypass. The agent stops when a page asks you to subscribe to
  continue.
- No purchases, payments, sign-ups or account creation. The agent refuses to
  click or press a key on any element whose text, accessible name or link
  mentions buy, pay, payment, checkout, order, purchase, subscribe, sign up,
  register, create account, place order or donate, and refuses to type into
  fields named for a card number, CVV or CVC, IBAN, expiry date or billing.
  These are keyword checks on the page structure, not a guarantee: watch the
  live view and stop the task if it heads somewhere you did not intend.
- One task at a time, at most the configured number of steps (10, 25 or 50)
  and at most 10 minutes per task.

## What you must not use it for

- Bulk scraping or crawling. Do not use it to collect data at scale, to
  bypass rate limits, or against a site's robots rules or terms of service.
- Collecting personal data about people.
- Accessing systems you are not authorised to use.
- Spam, fraud, harassment, or anything unlawful.

## Prompt injection

Web pages can contain text written to manipulate an AI agent ("ignore your
instructions and ..."). The agent is told to treat page text as untrusted
data, but no model is immune. Keep the allowlist short, do not put private
information in tasks, and check the step log to see what the agent actually
did.

## Network limits

The browser runs in an OpenShell sandbox. It can reach only the host names in
ALLOWED_DOMAINS over HTTPS, plus a demo site inside the sandbox. Add only
sites whose terms allow automated browsing.

## Models

The default model is NVIDIA Nemotron 3 Nano Omni, used under the NVIDIA Open
Model Agreement. Read the model card on Hugging Face before use.
