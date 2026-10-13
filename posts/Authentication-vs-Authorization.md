---
Title: "Authentication vs. Authorization: Who You Are Isn't What You Can Do"
Date: 10/13/2026
Summary: "Two words that look almost identical, do completely different jobs, and get mixed up in code all the time. Here's the difference, and why most access bugs live in the second one."
Author: Kenton Vizdos
Tags: Cybersecurity, Guides
---

Authentication and authorization share their first four letters, both get shortened to "auth," and they tend to live in the same middleware file.

They also do completely different jobs. Mixing them up is one of the easiest ways to ship a security bug that passes every login test you have.

## The Short Version

- **[Authentication](/glossary#authentication)** (AuthN) answers: **"Who are you?"**
- **[Authorization](/glossary#authorization)** (AuthZ) answers: **"What are you allowed to do?"**

Think of a hotel. The front desk checks your ID and hands you a key card: that's authentication. The key card opens *your* room and the gym, but not the room next door or the staff closet: that's authorization.

Checking your ID once doesn't mean every door should open.

| | Authentication | Authorization |
|---|---|---|
| Question | Who is this? | Can they do this? |
| When | Once, at sign-in (then remembered in a session or token) | On every request, for every resource |
| Examples | Password, passkey, MFA code, "Sign in with Google" | Roles, permissions, ownership checks, OAuth scopes |
| When it fails | `401 Unauthorized` | `403 Forbidden` |

Yes, HTTP 401 is called "Unauthorized" but actually means *unauthenticated*. Even the spec mixed them up.

## Where You've Already Seen Them

Most protocols you run into are clearly one or the other:

- **[SSO](/glossary#sso)** is authentication. One login proves who you are to many apps. It says nothing about what you can do inside each of them.
- **[OAuth](/glossary#oauth)** is authorization. It was built to let one app act on your behalf ("let this app read my calendar") without handing over your password.
- **[OIDC](/glossary#oidc)** is authentication bolted onto OAuth 2.0, because everyone was (mis)using OAuth to log people in anyway. Most "Sign in with..." buttons are OIDC (a few, like GitHub's, are still plain OAuth plus a profile lookup).

That last one sums up the whole problem: the industry built an authorization protocol, used it for authentication, and then wrote a second spec to make that safe.

## Most Bugs Live in Authorization

Authentication is hard, but it's a *solved* kind of hard. You can (and should) hand it to a library or an identity provider, and it happens in one place.

Authorization can't be outsourced the same way, because only your app knows its rules. Can a teacher see a student's grades? Only for students in their classes. Can a parent see attendance? Only for their own children, and only if the school says they have that right. Those rules are your business logic, and they have to be checked everywhere.

That's why Broken Access Control has sat at #1 on the [OWASP Top 10](https://owasp.org/Top10/) since 2021. The most common version looks like this:

```txt
GET /students/1041/attendance   ← your kid
GET /students/1042/attendance   ← someone else's kid
```

The user is fully authenticated. The session is valid. The only thing that changed is a number in the URL, and if the server never checks whether *this* user may see *that* student, it happily returns it. This has a name: an Insecure Direct Object Reference, or IDOR.

Here's what the fix looks like in Go:

```go
// Middleware has already authenticated the request.
// This handler still has to authorize it.
func (s *Server) getAttendance(w http.ResponseWriter, r *http.Request) {
	user := auth.UserFrom(r.Context())
	studentID := r.PathValue("studentID")

	// The bug is forgetting this check entirely.
	if !s.access.CanViewStudent(r.Context(), user, studentID) {
		// 404, not 403: don't confirm the student exists.
		http.NotFound(w, r)
		return
	}

	attendance, err := s.attendance.ForStudent(r.Context(), studentID)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	writeJSON(w, attendance)
}
```

Nothing about the login flow would have caught a missing `CanViewStudent`. Every test that logs in as a real user and loads *their own* data passes either way.

## Rules I Actually Follow

**Authenticate once, at the edge. Authorize on every request, close to the data.** Sign-in happens in middleware or at the identity provider. Permission checks happen where you know which record is being touched.

**Deny by default.** A new endpoint should be inaccessible until someone writes down who's allowed in, not open until someone remembers to lock it.

**Never let an ID from the client imply ownership.** A student ID in the URL is a *request*, not proof. Look the relationship up on the server, every time.

**Logging in is not permission.** "They're signed in" is the start of the question, not the answer. If the only check on an admin page is "is there a session?", every user is an admin.

**Return 404 for things a user can't see.** A 403 confirms the thing exists. Sometimes that alone is a leak.

## In One Line

Authentication tells you who's knocking. Authorization decides which doors open.

Get the first one from a good library. Write the second one yourself, carefully, everywhere it matters, because nobody else knows your rules.
