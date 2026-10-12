---
Title: The Standardless Standards of EdTech
Date: 10/12/2026
Summary: "We standardized everything in EdTech. Unfortunately, nobody standardized how to follow the standards."
Author: Kenton Vizdos
Tags: EdTech, Thinking Out Loud
#Syndications:
#  Bluesky: https://bsky.app/profile/kv.codes
---

The beautiful thing about standards is that everyone can agree on how things should work.

The unfortunate thing about EdTech is that nobody seems to agree on which standard we're talking about.

After several years of building integrations between Student Information Systems, Learning Management Systems, and everything in between, I've come to appreciate one universal truth: "We support the standard" is almost never the end of the conversation.

--- 

This blog will use quite a few acronyms. As a 10,000 foot overview, here are some important letters:

- **Student Information System (SIS)**: This is the Source of Truth for a "student" record.
- **Learning Management System (LMS)**: This is where a student "learns" and "completes coursework." 
- **Learning Content Provider (LCP)**: The LCP provides a variety of modules and activities to schools that will be completed with an LMS.
- **Other EdTech Systems**: These are "additional" services that a school may use which require student data to be synced.

Some of you may be thinking: that's a lot of things that need to talk together.

You'd be correct.

## A Quick Field Guide to the Standards

Let's go back to the beginning. As schools and vendors needed to communicate, they followed a Golden Standard: one specific CSV file per vendor:

| id | first | last | dob | course | etc |
|---|---|---|---|---|---|
| 1 | Kenton | Vizdos | 1/1/1970 | Algebra 1 A | other_critical_data |

Historically, this format got defined in one email, sent to one person. After a few months, questions may begin that nobody knows the answer to:

1. "What is ID? Is it the State Student ID? Is it our internal ID? Is it a new ID we need to link?" 
2. "What about the middle name? Some students need a middle name." 
3. "What courses are synced here? Active courses? Completed courses..?"
4. "Why is the DOB set to 1/1/1970? Are we using that date anywhere?" 
5. "Where does this CSV file live? Our school has 38 (s)FTP servers connecting 42 different systems together.." 

So the industry did what engineers always do: it wrote standards.

- **OneRoster**: a shared format for students, classes and enrollments, as CSV files or an API.
- **Learning Tools Interoperability**: how an LMS launches outside tools and gets grades back.
- **Ed-Fi**: a data model for SIS and state reporting.
- **Clever / ClassLink**: companies, not standards, but often how rostering and sign-in actually get done.
- **SIF**: the older standard many systems still carry around.

Each of these works on paper. Let's start with the one every school touches first: rostering.

## Rostering: Everyone Agrees on Students, Nobody Agrees on a Student

We can all agree: vendor-specific CSV drops are ***not*** the solution (right?). At the very least, the leading consortium, 1EdTech, brought The Standard of All Standards to life: OneRoster.

**OneRoster** is 1EdTech's attempt to get everyone in EdTech to agree on what a student, teacher, class, and enrollment actually look like when exchanged between systems. Instead of every vendor inventing their own CSV format (and inevitably naming the student ID column something completely different), OneRoster provides a common set of fields and rules for exchanging that information.

Sounds great, right? Well, there's a catch: OneRoster supports both CSV files and REST APIs, because apparently agreeing on what data looks like wasn't enough to agree on how to send it. 1EdTech does not require support for both transports. In defense of OneRoster, having multiple transports for the standard *has* made adoption slightly easier in older systems. 

It gets complicated, however, when you realize OneRoster REST can be used for both real-time requests and scheduled batch synchronization, while OneRoster CSV supports two entirely different modes of its own: Bulk (everything) and Delta (just the changes). And, of course, not every vendor supports Delta.

There are also multiple versions (notably 1.1 and 1.2), optional services, and plenty of room for vendors to interpret things differently. So when a vendor proudly announces, "We support OneRoster!", your first question should probably be: "Which version, which services, and how much of it?"

From a vendor POV, OneRoster is a pain as you need to incorporate **both** 1.1 and 1.2 (some schools have not / cannot upgrade!), live with its quirks, and be limited by its constraints.

> "What happens when a vendor needs data that OneRoster doesn't cover?"

Imagine you're building an online testing platform. You need to know which students receive extended testing time through an IEP or 504 plan. OneRoster can tell you who the student is, what class they're enrolled in, and who teaches it. But their testing accommodations (which live in the **SIS**)? Good luck!

Technically, OneRoster supports custom metadata fields. Great! Except now Vendor A calls it extendedTime, Vendor B calls it testing_accommodation, and Vendor C just asks the school to email them a spreadsheet.

Congratulations! **We've reinvented vendor-specific CSV files, but this time they're standardized.**

![Fortunately, the charging one has been solved now that we've all standardized on mini-USB. Or is it micro-USB? Shit.](/assets/blog/xkdc/standards_2x.webp)
["Standards" by Randall Munroe](https://xkcd.com/927)

## The Identity Problem

Okay, so we've agreed on a way to roster students. Surely all our systems now agree on *who* each student is, right?

Wrong.

Our next problem is **student identity**. To understand why this gets complicated, let's follow a student through their educational journey.

1. A parent finds a school.
2. The parent registers their child, providing their name, date of birth, home address, and parent contact information.
3. The school creates a student record and assigns an internal student ID.

Perfect! We now have a student record. We can identify them by their (District / School-specific) student ID, or perhaps match them using their name, date of birth, or parent's email address.

What could possibly go wrong?

Well, let's fast-forward a few years:

1. The student transfers to another school.
2. Their family moves to a new address.
3. A few years later, the student decides to return to their original school.
4. The parent fills out a new registration form, this time with a different email address and home address.
5. The school doesn't recognize the student and creates an entirely new record.

**Congratulations! We now have two students who are actually the same person.**

And remember that internal student ID we assigned earlier? Our SIS knows about it, but the LMS might have assigned its own ID. The testing platform might use a state-issued student ID, while another vendor might identify students by email address.

Now imagine trying to reconcile grades, transcripts, attendance records, and enrollments across all these systems.

OneRoster can standardize how we *exchange* student identifiers, but it doesn't magically solve the problem of determining whether two records represent the same human being.

**We've standardized how to send student records. We haven't standardized how to know who the student actually is.**

There are also other identity problems, like:
- **Two students with the same name, same DOB:** Registration assumes it's the same person: it's not.
- **Student uses a preferred name:** The SIS says "Robert," the LMS says "Bobby," and the testing platform says "Rob." Are these three different students?
- **Student's DOB was entered incorrectly:** One system says January 5, another says May 1. A typo during registration has now become a permanent identity mismatch.
- **Student account gets merged incorrectly:** Two different students are mistakenly identified as the same person. Now their grades, records, and potentially sensitive information are mixed together.
- **Any time any of this information changes, all systems need to stay in sync**. Yeah, good luck.

Turns out, identifying a human is significantly harder than identifying a row in a database.

## LTI: Same Spec, Different Dialects

Okay, so we've figured out how to identify our students (hopefully). We've got them enrolled in the right courses, in the right LMS, and all our systems agree on who they are.

Now, wouldn't it be nice if students could actually use the educational tools we've purchased without needing 15 different accounts?

Enter **Learning Tools Interoperability (LTI)**, another standard from our friends at 1EdTech.

In theory, LTI allows an LMS to securely launch external learning tools, pass along information about the student and their course, and even receive grades back. A student clicks an assignment in their LMS, the external tool opens, and everything just works.

You can probably guess where this is going.

When an LTI activity is embedded, the LMS acts like the outer container and the LTI tool appears inside the LMS page, usually in an iframe. From the student's perspective, it looks like part of the LMS. Technically, though, the content inside that embedded frame is being served by a different application entirely.

So the student is still "in Canvas" or "in Schoology," but the quiz, simulation, or assignment they are interacting with may actually be coming from the vendor's own system. The LMS provides the surrounding chrome—navigation, course context, assignment link—while the LTI tool provides the activity itself:

![Diagram showing Browser -> LMS -> LTI Activity relation](/assets/blog/standards/lti.webp)

*(Depending on the LMS and tool configuration, the launch may appear in an iframe, a new tab, or a full-page tool view.)*

Similarly to the previous standards, there are also multiple versions of LTI:

- **LTI 1.0**: The original standard, allowing an LMS to launch external learning tools using OAuth 1.0-based request signing.
- **LTI 1.1**: Expanded on the original with support for returning grades to the LMS. Simple, widely adopted, and now considered legacy.
- **LTI 1.3**: A major security overhaul, replacing OAuth 1.0 request signing with OpenID Connect (OIDC) and signed JWTs.
- **LTI Advantage:** Not technically another version, but a collection of additional services built on LTI 1.3, including grade passback, roster retrieval, and deep linking.

And, naturally, not every LMS supports every version or every optional service. So when someone says, "We support LTI," we're right back to asking: "Which version, and which parts?" For the most part, the authentication flows differ for each version:

| LTI version | Authentication flow |
|-------------|-----------------------------|
| LTI 1.1	| OAuth 1.0a request signing |
| LTI 1.3 launch | OIDC Third-Party Initiated Login + Implicit(ish) Flow |
| LTI Advantage API services | OAuth 2.0 Client Credentials Grant |

And here's a fun little detail: remember OneRoster? The standard we just spent all that time talking about?

Well, LTI Advantage includes something called **Names and Role Provisioning Services (NRPS)**, which allows an external tool to retrieve a list of students and teachers enrolled in a course.

Sound familiar?

That's because we're essentially rostering students again! Except this time, instead of using OneRoster's CSV files or REST APIs to exchange roster data across systems, we're using an entirely different API to retrieve membership information from the LMS, **typically scoped to a particular course.**

To be fair, they solve slightly different problems: OneRoster is designed for broader data synchronization (read: school-wide data sync), while NRPS lets a launched learning tool discover who's in its course (helpful to limit shared data when only 1 course requires a specific vendor).

So yes, we have two different standards, from the same standards organization, for retrieving lists of students.

---

Oh, and one more thing! Remember how LTI tools are commonly embedded within an iframe?

Well, browsers don't particularly like third-party cookies anymore. Safari, for example, blocks them by default. Unfortunately, many LTI implementations rely on those cookies to maintain authentication state or keep students logged in.

So now your perfectly functional LTI integration might suddenly stop working because the student's browser refuses to store a cookie.

Fortunately, 1EdTech has introduced LTI Platform Storage, which lets tools store information through the LMS instead of relying on third-party cookies.

Unfortunately, that requires the LMS to support it, too.

And if it doesn't (which is VERY common)? You'd better have a fallback, like recommending launching the tool in a new tab (LTI providers DO NOT control how a launch occurs!), because "your browser doesn't support our authentication flow" isn't a particularly acceptable reason to prevent a student from completing their coursework.

**Congratulations! We've standardized the integration, but now we have to work around the browser to actually use it.**

[Read more about how I solved third-party cookie fallbacks in go-lti](#lti-13-only-and-a-button-for-when-the-cookie-fails)

## Time Is a Social Construct (Especially in Schools)

Of course, even when we finally agree on the format, the identifiers, and how systems communicate, there's still one tiny detail left: **agreeing on what the data actually means.**

For example, you'd think a date would be relatively straightforward.

```sh
curl -X POST '/CreateEnrollment' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data 'StudentIndex=<student ID>' \
  --data 'SectionIndex=<course ID>' \
  --data 'StartDate=10/13/2026' \
  --data 'EndDate=10/20/2026'
```

Well how convenient! The start date is Oct. 13 2026, and the end date of this course is on Oct. 20 2026.

What is not mentioned anywhere, nor shown in the SIS UI, is that the start dates are saved in the **server location, which is not set to UTC, and instead America/New_York.** This effectively makes the dates set to:

```txt
StartDate: 2026-10-13T04:00:00.000Z
EndDate: 2026-10-20T04:00:00.000Z
```

**This timezone issue then compounds, downstream.** The LMS is not guaranteed to be in UTC nor the SIS timezone, which creates situations where:

1. Teacher enrolls student, expects course to finish Oct. 20 at midnight. 
2. SIS saves that as `2026-10-20T04:00:00.000Z`
3. SIS sends to LMS, which converts to Arizona time: `2026-10-19T21:00:00.000-07:00`

And now, on Oct. 19 @ 9pm, everyone is confused why the student’s course was dropped.

**This issue becomes especially concerning in non-traditional online learning environments where students pay for access to a course: you must juggle 5 different timezones.**

1. What timezone is the user in?
2. What timezone is the server WE control in?
3. What timezone is the SIS in?
4. What timezone is the LMS in?
5. What timezones are all of the other systems in?

And finally, **what do we show the user?** *(hint: make it work for whatever timezone they can reasonably expect, like the timezone of the school)*

While the issues related to time so far have related to physical time, a related issue is how **terms, semesters, and grading periods** are defined: some schools have rolling terms (very popular in online where start/end dates are different per student), some schools have terms (enroll for 1 term, then end the course), etc. 

Some SIS systems *do not* support rolling enrollment at all, they must be term-attached; others only support rolling. 

## Why It Stays This Way

After all of this, you might be wondering: **Why haven't we just agreed on one standard and moved on with our lives?**

Well, there are a few reasons, and surprisingly, not all of them are bad.

**First, schools have wildly different needs.**

A traditional public high school, a fully asynchronous online school, and a university might all use an SIS and an LMS, but what they actually *need* those systems to do can be completely different.

Take attendance, for example. A traditional school might care whether a student was physically present for a class period. An online school might need to track instructional hours, assignment activity, or guardian-verified attendance. Both call it "attendance," but the underlying data, workflows, and reporting requirements can be completely different.

Now multiply that by 50 states, thousands of districts, countless school policies, and a healthy dose of regulatory requirements.

**A standard can't reasonably anticipate every school's unique needs.** So vendors add custom fields, build proprietary APIs, and create school-specific integrations. Sometimes, that's genuinely the right solution.

**Second, standards take time, and software doesn't stop evolving.**

By the time a standards organization has identified a problem, assembled stakeholders, agreed on a solution, published a specification, and convinced vendors to implement it, the industry may have already developed three different ways of solving that problem.

And even when a new standard comes out, schools can't necessarily upgrade overnight. Their SIS might not support it, their LMS might require a migration, or their IT department might have approximately zero interest in replacing an integration that's been working since 2014.

So vendors continue supporting older versions alongside newer ones. **Congratulations, we now have even more standards to maintain!**

**Third, and perhaps less innocently, vendor lock-in.**

Interoperability is great for schools. It's not always great for the companies selling them software.

Think about it: if a school can easily export its data, migrate to another SIS, and reconnect all its existing learning tools without rebuilding every integration, switching vendors becomes significantly easier.

That's wonderful for competition. It's not necessarily wonderful for a vendor whose business benefits from making switching expensive.

I'm not suggesting every proprietary integration is some evil scheme to trap schools. Sometimes a custom API is genuinely better suited to a product's needs. But there's also a very real business incentive to keep customers dependent on your ecosystem.

**Finally, nobody wants to be the first one to change.**

A vendor might fully support the latest standard, but that doesn't help if the schools it serves are still using an older version. Likewise, a school might want to modernize, but that doesn't help if its critical vendors haven't implemented the new specification.

So everyone keeps their existing integrations running, adds another adapter when necessary, and hopes the next migration will finally clean everything up.

It usually doesn't.

And that's the frustrating reality: **standards are supposed to make systems interoperable, but interoperability is ultimately determined by what schools and vendors actually implement—not what a specification says they should.**

## How I Actually Cope

In reality, like with many other systems, engineers must expect messy data. What I've done at [Edvizion](https://edvizion.com) is to define our internal data model. Our products and services live outside of the SIS->LMS loop, requiring additional non-standard data (e.g. attendance data, parent info, etc):

> What data do *we* care about? 

The first step here is to answer the above question. Once we defined that, we ensured our Core was written with [hexagonal architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/hexagonal-architecture.html), which allowed us to write multiple *adapters* for each data type.

### Rostering: map it per school, and own the dedup.

We're small enough that every school gets its own field mapping, configured without a deploy. School A's `extendedTime` and School B's `testing_accommodation` both land in the same field in our model. Vendor C's emailed spreadsheet goes through our own CSV enrichment format: a fixed schema that's unique to us (yes, we're part of the problem).

For rostering, we only support bespoke connections. Yes, I just spent a post complaining that vendors do this. Being small means we get to pick our battles, and when a school shows up, a CSV is probably the easiest way to launch.

None of our upstream connections support the concept of "Delta" syncs (nothing gets a "last updated" date..), so every sync is a full "Bulk" export. That means we're the ones figuring out what changed. Every sync gets compared against what we already have, and dedup logic does a lot of heavy lifting.

As for data quality, we trust what we're given. If the SIS says the DOB is `1/1/1970`, that's the DOB. The SIS is the source of truth, and the school owns what's in it. Our job is to reflect that data faithfully, not quietly "fix" it into something nobody can trace back.

**The rule:** the school owns the data; we own the mapping.

### Identity: we automate the confident part, and hand the rest to a human.

Strong identifiers (an SIS ID we've already seen, a state student ID) link automatically. Everything fuzzier (same name and DOB, a new email on a returning student) goes to a review queue. We never auto-merge. A duplicate record is annoying; a bad merge is a privacy incident.

Guardians are where this gets real. Our Attendance Logs product asks a guardian to approve their student's hours every week, which means a guardian account can see that student's attendance. The SIS will happily give us a list of "guardians," but it can't tell us who should have access: an emergency contact, a grandparent, a non-custodial parent, a guardian whose rights changed last month and whose record didn't.

[There's no standard for that, and no field we could trust if there were](https://ed.link/docs/guides/v2.0/security/parent-and-guardian-access). So we don't guess. Every guardian invite sits in a queue until the school's Attendance Clerk confirms it. It's slower than full automation, and that's the point: the person who knows the family makes the call, not our matching logic.

**The rule:** automate what you can verify, and queue what you can only infer.

### LTI: 1.3 only, and a button for when the cookie fails.

We only support LTI 1.3. We don't roster through LTI either; no NRPS. Rosters come in through the rostering adapters, so there's one source of truth for who's enrolled.

Platform Storage would be the proper fix for blocked cookies, but our primary LMS doesn't support it, and I haven't had a compliant LMS to test against. So [go-lti](https://github.com/Vizdos-Enterprises/go-lti) doesn't implement it yet. Instead, when the cookie fails, students get a CAPTCHA-style "Click here to prove you're human" button. That click opens a new tab, and we hand the session over to it with a PKCE-protected credential exchange. The tool then runs first-party, and the cookie problem disappears.

![Human Check](/assets/blog/standards/human.webp)

Unlike what the screen says, this isn't a security check. We just don't want to bother trying to guide the student through "Here's what's wrong with your browser." One click is much smoother.

**The rule:** build for the LMS you have, not the spec you wish it implemented.

### Time: UTC inside, timezones at the edges.

Everything in our core is UTC. Timezones only exist in the adapters. On the way in, an adapter converts the source's dates to UTC; on the way out, it converts them back to whatever the downstream system expects.

That only works if you know the source's timezone, so we ask for it during onboarding for every integration. Sometimes nobody knows. Remember the SIS whose server was quietly set to `America/New_York`? In those cases, we stumbled across the fact on our own during testing.

We also only support rolling enrollment, which conveniently lets us skip the whole terms-vs-semesters problem. For now.

**The rule:** always double-check the timezone. Then check it again.

## The Standard Is Whatever Shows Up in the SFTP Folder

We started with vendor-specific CSV files because nobody could agree on how systems should communicate.

Then we invented standards so everybody could agree.

Then we invented multiple versions of those standards, optional services, vendor-specific extensions, and proprietary integrations to fill in the gaps.

And in the great year of 2026, I still regularly find myself having conversations that end with: "Just tell me what columns you need in the CSV."

Maybe the real standard was the SFTP server we met along the way.
