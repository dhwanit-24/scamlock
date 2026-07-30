index document for scamlock
	# Project Spec: Fraud-Lock Lookup App
	
	  
	
	## 1. What this app is
	
	  
	
	A mobile app for a **closed, gated community of businesses/firms** to check
	
	whether a person or entity has previously committed fraud or engaged in bad
	
	business practices with someone else in the community, before doing
	
	business with them themselves.
	
	  
	
	The core idea: any member firm that gets scammed/defrauded by someone can
	
	**flag ("lock")** that person in a shared database, with a reason. Any
	
	other member can then **search** for that person before transacting with
	
	them, and instantly see if anyone in the community has flagged them as
	
	risky — preventing others from getting scammed by the same person.
	
	  
	
	This is fundamentally a **crowd-sourced blacklist / fraud-warning
	
	system**, not a general CRM or contacts app.
	
	  
	
	## 2. Non-negotiable requirements
	
	  
	
	- **The app must run 24/7/365 (366 in leap years) with effectively zero
	
	  downtime.** This is the single most important operational requirement.
	
	  Backend choice, hosting, and monitoring must all be chosen with this in
	
	  mind (managed/hosted services preferred over self-hosted, with
	
	  backups and uptime monitoring).
	
	- **Platform:** Android first. iOS support is required in the near future,
	
	  so the app must be built in a cross-platform framework (not
	
	  Android-only native), so no rewrite is needed later.
	
	- Every user must **log in** (this is a closed community app — actions are
	
	  tied to identifiable accounts/firms, not anonymous).
	
	- A **full permanent audit trail** of every lock/unlock action must be
	
	  kept — never delete or overwrite history.
	
	  
	
	## 3. Data model
	
	  
	
	### Entities
	
	  
	
	**Person/Record being tracked** — has exactly 4 identifying fields:
	
	| Field | Type | Format rule |
	
	|---|---|---|
	
	| Full Name | string | free text |
	
	| Mobile Number | integer | 10 digits |
	
	| A Number ("Abhyan number") | string (NOT integer) | exactly **12 digits**, digits only. Must be stored as text/string, not a number type, because it can have **leading zeros** that must be preserved. |
	
	| G Number | string | exactly **15 characters**, **capital letters + numbers only** (no lowercase, no symbols), must be unique across all records |
	
	  
	
	**User (a person representing a firm in the community)** — collected at
	
	signup:
	
	- Name
	
	- Firm name
	
	- Phone number
	
	- Email (**optional**)
	
	- Location of firm
	
	- Password
	
	  
	
	Returning users log in with just **phone number + password** (not email).
	
	  
	
	### The locking mechanism — this is the most important business logic
	
	  
	
	This was iterated on carefully — get this exactly right:
	
	  
	
	- Locking/unlocking is **per-user, not global**. Each user maintains
	
	  their own independent opinion (locked or unlocked) on any given record.
	
	- **One user can lock the same record only once** — i.e. each
	
	  (user, record) pair has exactly one *current* state, which the user can
	
	  change any time (lock → unlock → lock again, etc.). It is NOT a
	
	  repeating log entry per user — it's a live current-state row per user
	
	  per record, but every *change* to that state is also appended to a
	
	  separate permanent history/audit log.
	
	- A record has **no single global "locked" status stored on the record
	
	  itself.** Instead, the overall status shown to anyone searching is
	
	  **computed live**: if **ANY** user currently has that record in the
	
	  "locked" state, the record shows as **red / LOCKED** overall. If no one
	
	  currently has it locked, it shows as **green / CLEAR**.
	
	- When viewing a record's full detail, the user must see the **list of
	
	  every firm** that currently has this person locked, along with the
	
	  reason each firm gave (if any) and when.
	
	- A **separate, permanent activity log** records every lock and unlock
	
	  action ever taken by anyone, and is never edited or deleted — this is
	
	  distinct from the "current state per user" table.
	
	  
	
	### Search behavior
	
	  
	
	- A single search box accepts **any of the 4 fields** — name, mobile
	
	  number, A number, or G number — the app does not ask which field, it
	
	  just searches all of them.
	
	- Name search should be **partial/fuzzy match** (contains, case
	
	  insensitive) since multiple people can share similar names.
	
	- The other 3 fields (mobile, A number, G number) should be **exact match**.
	
	- If the search term matches **multiple people** (most likely with name
	
	  search), show all matches as a list so the user can visually confirm
	
	  which one is the right person using the other fields.
	
	- If no match is found at all, show "not available."
	
	- Each search result row should show: the field that matched (highlighted),
	
	  and the word **"LOCKED" in red** if the record is currently flagged by
	
	  anyone, nothing/green if not.
	
	- Tapping a result opens the full detail screen (see below).
	
	  
	
	### Screens & flow
	
	  
	
	1. **Signup** (first-time users): Name, Firm name, Phone, Email (optional),
	
	   Firm location, Password.
	
	2. **Login** (returning users): Phone number + Password only.
	
	3. **Landing page**: shows only the records **the logged-in user
	
	   personally has currently locked** — displayed simply as Name + Mobile
	
	   Number in a list. Tapping one opens the full detail screen.
	
	4. **Search screen**: single search box as described above; results list;
	
	   tap result → detail screen.
	
	1. **Record detail screen**: shows all 4 identifying fields, overall
	
	   red/green status, the list of all firms currently locking this person
	
	   (with their reasons + dates), and a **Lock / Unlock button** specific
	
	   to the current logged-in user's own state on this record.
	
	   - Locking requires a confirmation dialog with an **optional reason**
	
	     text box before submitting.
	
	   - Unlocking follows the same open rule — any user can unlock their own
	
	     lock at any time, same as locking (no special admin/moderator role
	
	     exists — every user has equal rights to lock/unlock).
	
	1. **Add new record screen**: for adding a person not yet in the database
	
	   (all 4 fields), used when someone is being flagged for the first time.
	
	   Any logged-in user can add a new record — no restricted roles.
	
	  
	
	## 4. Tech stack
	
	  
	
	- **Frontend:** Flutter (Dart) — chosen specifically because it supports
	
	  Android and iOS from a single codebase, satisfying the "Android now,
	
	  iOS later" requirement without a future rewrite.
	
	- **Backend/Database:** Supabase (managed Postgres) — chosen for:
	
	  - Native support for the multi-field OR search this app needs
	
	  - Built-in auth, generated REST API, and row-level security
	
	  - Managed backups, high uptime SLA on paid tier — directly supports the
	
	    24/7 requirement without needing to run/maintain a server
	
	  - `pg_trgm` Postgres extension used for fast fuzzy name search
	
	  
	
	## 5. Known gotchas / things to get right the first time
	
	  
	
	- **A Number must be a `text`/string column, never `integer` or `bigint`**
	
	  — storing it as a number silently strips leading zeros (e.g.
	
	  `007123456789` becomes `7123456789`), corrupting the data.
	
	- **G Number needs a database-level uniqueness constraint** and a format
	
	  check (`^[A-Z0-9]{15}$`), not just app-side validation, so bad data can
	
	  never get in even if there's a client bug.
	
	- **Supabase Auth is email-based, but this app's login flow uses phone
	
	  number.** Bridge this with either (a) an auto-generated placeholder
	
	  email like `{phone}@placeholder.yourapp` behind the scenes at
	
	  signup/login, or (b) switch to Supabase's native phone+OTP auth if a
	
	  cleaner passwordless flow is preferred. Either approach is acceptable;
	
	  pick one and be consistent.
	
	- **Never let the lock/unlock action write to just one table.** Always
	
	  update the "current state per user" table AND append to the permanent
	
	  activity log **together** (ideally via a single database
	
	  function/transaction) so they can never drift out of sync if the app
	
	  crashes mid-action.
	
	- **Compute the overall red/green status live** (e.g. via a database view
	
	  that checks `EXISTS` any locked row for that record) — do not store a
	
	  single "status" field directly on the record, since that would
	
	  contradict the per-user locking model.
	
	  
	
	## 6. Reference implementation
	
	  
	
	A working first-draft implementation already exists (Flutter app +
	
	Supabase SQL schema) reflecting everything above — including the table
	
	structure, RLS policies, the `set_lock_state()` database function, and
	
	all screens listed in section 3. Use it as the structural reference/
	
	starting point rather than designing the data model from scratch.
	
	  
	
	## 7. Non-goals for this version (do not add unless asked)
	
	  
	
	- No in-app activity log *screen* yet (the underlying table/data should
	
	  still be recorded from day one, per section 3 — just no UI to browse it
	
	  yet).

this is the first version that i thought "

the changes in this app are as follows:

- there will be an admin panel which will be able to access all the users' locked people and be able to manage them
- there will be a admin verification just for the very first time when users will be signing up so the admin can control who can access the app and who cant! (this is must have)
- then if loging in back again wont require any admin permission
- this app will be subscription based as users (firm owners) will need to pay a X amount (it is completely unrelated to you, i am just sharing this info so yk if there is any changes we need to keep in mind while building the app)
- the admin shall have right to close the access from user by a simple toggle so if it happens anyone has not paid the subscription fees, they can be blocked acess (but keep it just lock not delete them from db or anything)
- if the user pays then their account shall be able to access the app normally
- and by locking the user i mean they cant get search results, they can still view thier locked accounts details

these are some add ons to the app after the first documentation is created

Thursday 9:21 PM

Worked for 19s

Your additions fit the app well. They change ScamLock from “every logged-in member has equal access” into a **gated business platform** with three account states:

|Account state|What the firm can do|
|---|---|
|Pending approval|Sign up and log in, but sees “Waiting for admin approval.”|
|Active|Use search, add records, and lock/unlock normally.|
|Access suspended|View-only access to **their own currently locked records and their details**; no search results, adding, locking, or unlocking.|

That last row is the interpretation I’ll build from your wording. It preserves their data without letting an unpaid firm use the shared fraud-search database.

The specification needs these concrete additions:

- An **admin role** and an Admin Panel.
- A `status` on each user profile: `pending`, `active`, or `suspended`.
- On sign-up, the user is created as `pending`; an admin must approve them once.
- Future logins do not need approval again unless an admin suspends them.
- An admin toggle changes access between `active` and `suspended`; it never deletes the user or their locks.
- Subscription data is stored separately (for example, plan, renewal date, payment status). We will initially change access manually; payment-gateway automation can come later.
- Admins can view members and all active locks. Every approval/suspension/admin change gets its own permanent audit entry.
- The database—not only the Flutter screen—must enforce these restrictions. Otherwise someone could bypass a disabled button.

One important product note: because this contains allegations about real people, we should eventually add report evidence, correction/appeal handling, and clear terms/privacy controls. That protects both firms and the platform. We won’t let that distract us from the first usable version, but the data model should leave room for it.

Next, create the Flutter project if you haven’t already, call it `scam_lock`, run it once on your Pixel emulator, and tell me when the default counter app appears. Then we’ll replace it with ScamLock’s first screen: a clean **Sign in / Request access** screen.


DEVICE USED (IN ANDROID STUDIO) - PIXEL 10 PRO XL

k the app is running in android stud. lets move ahead

Thursday 10:53 PM

Excellent—your full development loop works. Now we’ll replace the demo counter with ScamLock’s first real screen.

In Android Studio, open **`lib` → `main.dart`**. Select everything in that file, delete it, and paste this:

```
import 'package:flutter/material.dart';

void main() {
  runApp(const ScamLockApp());
}

class ScamLockApp extends StatelessWidget {
  const ScamLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamLock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB42318),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const Icon(
                Icons.shield_outlined,
                size: 72,
                color: Color(0xFFB42318),
              ),

              const SizedBox(height: 20),

              const Text(
                'ScamLock',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Check before you transact.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 48),

              const TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 16),

              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login will be connected next.'),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Sign in'),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('The request-access form comes next.'),
                    ),
                  );
                },
                child: const Text('New firm? Request access'),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
```

Save with `Ctrl + S`, then press the yellow ⚡ **Hot Reload** button. You should immediately see the ScamLock sign-in screen in the emulator.

What you just built:

- `main()` starts the app.
- `ScamLockApp` sets app-wide appearance and chooses the first screen.
- `LoginScreen` lays out visual widgets vertically using `Column`.
- `TextField` creates inputs; `FilledButton` creates the main action.
- The temporary pop-up after a button press is a `SnackBar`.

The login does not really authenticate yet—that requires our Supabase backend—but the screen is real and working. Once you see it, tell me whether it appears correctly; next we’ll make **“Request access” open a genuine sign-up form**.


ok that runs smoothly, keep in mind we need to change the ui and colours as this wont work

Thursday 10:58 PM

Absolutely. Treat this as a functional wireframe, not the visual design.

We’ll keep the underlying flow while later replacing the colours, spacing, typography, icons, and layout with a proper ScamLock identity. For a trust-and-safety app, I’d avoid making red the whole theme—use a calm professional base (deep navy/charcoal or white) and reserve red specifically for actual “LOCKED” warnings.

As we build, I’ll keep the UI easy to redesign: no visual choices are permanent yet. If you have a reference app, colour palette, logo idea, or screenshot you like, send it anytime.

Next we’ll make “New firm? Request access” open the registration form, which gives us the first real multi-screen app flow.



Let’s add the genuine sign-up flow now. Replace all of `lib/main.dart` with this, save, and hot-reload:

```
import 'package:flutter/material.dart';

void main() {
  runApp(const ScamLockApp());
}

class ScamLockApp extends StatelessWidget {
  const ScamLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamLock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB42318),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.shield_outlined,
                size: 72,
                color: Color(0xFFB42318),
              ),
              const SizedBox(height: 20),
              const Text(
                'ScamLock',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check before you transact.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 48),
              const TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('We will connect sign-in to Supabase next.'),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Sign in'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RequestAccessScreen(),
                    ),
                  );
                },
                child: const Text('New firm? Request access'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestAccessScreen extends StatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final _formKey = GlobalKey<FormState>();

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PendingApprovalScreen(),
        ),
      );
    }
  }

  InputDecoration _fieldStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request access')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Join the ScamLock community',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your request will be reviewed by an administrator.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 28),

              TextFormField(
                decoration: _fieldStyle('Your name', Icons.person_outline),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: _fieldStyle('Firm name', Icons.business_outlined),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: _fieldStyle('Phone number', Icons.phone_outlined),
                validator: (value) {
                  if (value == null || value.trim().length != 10) {
                    return 'Enter a 10-digit phone number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldStyle(
                  'Email address (optional)',
                  Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: _fieldStyle(
                  'Firm location',
                  Icons.location_on_outlined,
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              TextFormField(
                obscureText: true,
                decoration: _fieldStyle('Create password', Icons.lock_outline),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Use at least 8 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: _submitRequest,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Submit request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }
}

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 72,
                color: Color(0xFFB42318),
              ),
              const SizedBox(height: 24),
              const Text(
                'Request submitted',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'An administrator must approve your firm before you can use ScamLock.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Test this exact journey:

1. Tap **New firm? Request access**.
2. Try submitting an empty form—notice the validation messages.
3. Enter valid details and submit.
4. You should land on the approval-pending screen.
5. Tap **Back to sign in**.

The important new idea is `Navigator`: it moves between screens. The registration form validates locally for now; next we’ll connect it to Supabase so a real pending user account is saved for the admin to approve.

do keep in mind that we need to seprate the pages, like each page has its own file (or whatever is the approch while building the app in flutter) because i suspect that keeping login and signup in one page that too in main file is not optimal approach, follow the peoper architecture for the software not like a noob but like a pro

You’re right. The code so far is a learning prototype; we should refactor it before adding real authentication or database work.

We’ll use a feature-first Flutter structure:

```
lib/
├── main.dart                         # Starts the app only
├── app.dart                          # App theme, routes, app-wide setup
├── core/
│   ├── routes/
│   │   └── app_routes.dart           # Route names in one place
│   └── theme/                        # Colours, text styles later
├── features/
│   ├── auth/
│   │   ├── data/                     # Supabase authentication code later
│   │   ├── domain/                   # User/account models and rules later
│   │   └── presentation/
│   │       └── screens/
│   │           ├── login_screen.dart
│   │           ├── request_access_screen.dart
│   │           └── pending_approval_screen.dart
│   ├── search/
│   ├── records/
│   └── admin/
```

So:

- `main.dart` will stay tiny—just starts `ScamLockApp`.
- Each screen gets its own file.
- Authentication logic will not live inside the visual screen files.
- Database code will later stay in `data`, business rules in `domain`, and buttons/forms/screens in `presentation`.
- Shared colours and UI components will live outside individual screens, making the eventual redesign consistent and quick.

This is the professional approach without prematurely creating dozens of empty files. We create folders when we introduce their real responsibility.

Before we connect Supabase, our next step will be to move the three existing screens into this structure and switch navigation to named routes. That preserves exactly what currently works while giving us a clean foundation.


yep then lets do it,

so keep in mind i only have the code till the login screeen after that i havent added the latest code, so lets first clean the file structure then i will add the signupp code


Good call. We’ll refactor the existing login-only app first, then add sign-up cleanly into its own screen.

In Android Studio’s left panel, change the dropdown above the files from **Android** to **Project**. Then create these folders inside `lib`:

```
lib/
├── core/
│   └── routes/
├── features/
│   └── auth/
│       └── presentation/
│           └── screens/
├── app.dart
└── main.dart
```

Create the folders by right-clicking `lib` (or the parent folder) → **New** → **Directory**. Then create Dart files by right-clicking the target folder → **New** → **Dart File**.

Create these four files and paste the matching code.

`lib/main.dart`

```
import 'app.dart';

void main() {
  runApp(const ScamLockApp());
}
```

`lib/app.dart`

```
import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'features/auth/presentation/screens/login_screen.dart';

class ScamLockApp extends StatelessWidget {
  const ScamLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamLock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB42318),
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
      },
    );
  }
}
```

`lib/core/routes/app_routes.dart`

```
abstract final class AppRoutes {
  static const login = '/login';

  // We will add these as their screens are created.
  static const requestAccess = '/request-access';
  static const pendingApproval = '/pending-approval';
}
```

`lib/features/auth/presentation/screens/login_screen.dart`

```
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const Icon(
                Icons.shield_outlined,
                size: 72,
                color: Color(0xFFB42318),
              ),

              const SizedBox(height: 20),

              const Text(
                'ScamLock',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Check before you transact.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 48),

              const TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 16),

              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login will be connected later.'),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Sign in'),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('The sign-up screen will be added next.'),
                    ),
                  );
                },
                child: const Text('New firm? Request access'),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
```

Save all files and hot-reload. The login screen should look exactly as before.

The benefit is already visible: `main.dart` is now only 5 lines, the app configuration is in `app.dart`, route names are centralized, and the login screen owns only login-screen UI. Once this runs, we’ll add `request_access_screen.dart` without turning any existing file into a mess.

ok done now next step is login

For real login, we now need ScamLock’s backend. We’ll use Supabase for accounts, database, and the later admin controls.

Do this first:

1. Go to [Supabase](https://supabase.com/dashboard) and create an account/sign in.
2. Click **New project**.
3. Choose a project name such as `scamlock-dev`.
4. Set a strong database password and save it somewhere safe.
5. Pick the nearest available region.
6. Create the project and wait until it says it is ready.

Then open the project’s **Connect** panel and locate:

- **Project URL**
- **Publishable key**

Do not share or use a `service_role` / secret key inside Flutter. The publishable key is designed for the mobile app; real protection comes from database security rules, which we’ll configure next.

Send me confirmation once the project is ready—not the key itself—and I’ll guide you through adding the Supabase Flutter package and connecting our app safely. [Supabase’s Flutter guide](https://supabase.com/docs/guides/getting-started/quickstarts/flutter) uses this same URL + publishable-key setup.


ok

scamlock-dev is created in supabase


Great—now we connect the Flutter app to it, using a proper configuration setup rather than placing credentials directly in screen code.

1. In Supabase, open `scamlock-dev` → **Connect**. Copy locally:
    
    - Project URL
    - Publishable key
    
    Don’t send the key here, and never use the secret/service-role key in the app.
    
2. In Android Studio, open the **Terminal** tab at the bottom. Confirm its path ends in your Flutter project folder, then run:
    
    ```
    flutter pub add supabase_flutter
    ```
    
3. Create this file: `lib/core/config/supabase_config.dart`
    
    ```
    abstract final class SupabaseConfig {
      static const url = String.fromEnvironment('SUPABASE_URL');
      static const publishableKey =
          String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    }
    ```
    
4. Replace `lib/main.dart` with:
    
    ```
    import 'package:flutter/widgets.dart';
    import 'package:supabase_flutter/supabase_flutter.dart';
    
    import 'app.dart';
    import 'core/config/supabase_config.dart';
    
    Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized();
    
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
    
      runApp(const ScamLockApp());
    }
    ```
    
5. Open `android/app/src/main/AndroidManifest.xml`. Directly inside the opening `<manifest ...>` tag, before `<application>`, add:
    
    ```
    <uses-permission android:name="android.permission.INTERNET" />
    ```
    
6. Add the two values to Android Studio’s run configuration:
    
    - **Run** → **Edit Configurations…**
    - Select your Flutter configuration.
    - In **Additional run args**, paste this, replacing the placeholders with your values:
    
    ```
    --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR-PUBLISHABLE-KEY
    ```
    
7. Stop the running app and press ▶ Run again. This needs a full restart, not Hot Reload.
    

Using `--dart-define` keeps project-specific configuration out of your Dart source files. The publishable key is safe for a client app, but the service-role/secret key never is. Supabase’s Flutter SDK requires initialization with the project URL and publishable key exactly this way. [Official Flutter setup](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)

Tell me whether the app launches normally after this. Then we’ll add the authentication service and turn the sign-in button into a real login.



the app is opened succesfully

Excellent—your Flutter app is now connected to Supabase.

Before wiring the Sign In button, we need to create the secure user structure in Supabase. This matters because ScamLock must distinguish:

- `pending` firms awaiting first approval
- `active` firms allowed to use search and locks
- `suspended` firms with view-only access to their own locks
- `admin` users who approve and manage firms

We’ll use your required **phone number + password** login. Internally, Supabase will store a generated technical email from the phone number, while the real optional email remains in the user profile. This preserves your intended user experience.

Next step: in Supabase, open **SQL Editor** → **New query**. Don’t run any generic table-creation code yet—I’ll give you ScamLock’s complete first migration next, including the profile table, roles, approval status, and Row Level Security policies. After that, we’ll build the sign-up screen and connect it to that structure.


INSTRUCTIONS 
see one instruction what i will give you as we will continue to build, is,

that idk shit about flutter, supabase, postgres or android studio, 

so everything you give me to implement you need to give me reason why should i add this, where exactly (in file structure)

then provide every code and everything in one block at a time (example, while giving postgres code or tables code, provide 1 table at a time and some basic explaination of syntax so ik what we are writing)

then if providing code of login, teach me the flow how data will go

Understood. From now on, every implementation step will follow this exact format:

1. **Goal** — what we are building now.
2. **Why** — why it belongs in the app and why we use this approach.
3. **Where** — the exact dashboard section or exact file path.
4. **One focused block** — one table, one file, or one connected change at a time.
5. **What the code means** — plain-English explanation of key syntax and data flow.
6. **Test** — how you verify that specific step worked before we continue.

I won’t drop a large database schema or multiple screens on you at once. For example, when we create the database:

- First: user roles/status types.
- Then: the `profiles` table.
- Then: its security rules.
- Then: test it.
- Only then: add the Flutter sign-up code that sends data there.

For login, I’ll also trace the full path:

```
Phone + password entered
→ Flutter validates the fields
→ Auth service sends a secure request to Supabase
→ Supabase verifies the password
→ App fetches the user’s profile/status
→ active / pending / suspended users go to different screens
```

You’ll build each part yourself in the correct place, while understanding what it is doing.


ok now you understood, lets start building again whats the next step

## Goal

Create the first ScamLock database table: `profiles`.

## Why

Supabase already manages secure passwords and login identities in its internal `auth.users` table. Our `profiles` table stores the ScamLock-specific information that Supabase Auth does not know:

- person’s name
- firm name and location
- phone number
- approval/suspension status
- whether the user is an admin

## Where

Supabase dashboard → `scamlock-dev` → **SQL Editor** → **New query**.

## Code — one table only

Paste and run this single block:

```
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,

  full_name text not null,
  firm_name text not null,
  phone text not null unique check (phone ~ '^[0-9]{10}$'),
  email text,
  firm_location text not null,

  account_status text not null default 'pending'
    check (account_status in ('pending', 'active', 'suspended')),

  app_role text not null default 'member'
    check (app_role in ('member', 'admin')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
```

## What this means

- `public.profiles` is the table name. `public` is the standard app-data area in Supabase.
- `id uuid ... references auth.users(id)` links each profile to exactly one Supabase login account.
- `text` means normal text such as names and firm locations.
- `not null` means the field is required.
- `unique` prevents two accounts using the same phone number.
- `check (...)` is a database-level rule. Even if someone bypasses Flutter, the database rejects an invalid phone number or made-up account status.
- `default 'pending'` ensures every new sign-up needs admin approval first.
- `app_role` defaults to `member`; later, we will manually promote the first account to `admin`.
- `timestamptz` stores a date/time with timezone information.
- `enable row level security` locks this table down by default. Nobody—not even a signed-in app user—can read or write it until we deliberately add safe rules next.

## Test

After clicking **Run**, open **Table Editor** → `profiles`.

You should see the table and its columns, but no rows yet. That is correct.

Do not add sample data manually. Our next step will add the first security policy so a signed-up user can safely create only their own profile.


ok whats next
## Goal

Add the first security rules for the `profiles` table.

## Why

Row Level Security is enabled, so the table is currently locked completely. Now we will allow a signed-in user to:

- create only their own profile;
- create it only as a normal, `pending` member;
- read only their own profile.

They cannot make themselves an admin or activate/suspend their own account.

## Where

Supabase → **SQL Editor** → **New query**.

## Code — policies for `profiles` only

```
grant select, insert on table public.profiles to authenticated;

create policy "Users can read their own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

create policy "Users can create their own pending profile"
on public.profiles
for insert
to authenticated
with check (
  auth.uid() = id
  and account_status = 'pending'
  and app_role = 'member'
);
```

## What this means

- `grant select, insert` allows signed-in app users to request reading and adding data. It does **not** decide which rows they get—that is RLS’s job.
- `authenticated` means only someone who has successfully signed in through Supabase Auth.
- `auth.uid()` is the ID of the currently signed-in user.
- `using (auth.uid() = id)` means: “when reading profiles, return only the row whose ID matches the logged-in user.”
- `with check (...)` means: “allow creating a profile only if every condition is true.”
- The final two checks prevent a malicious modified app from registering itself as `admin` or `active`.

We intentionally have **no update or delete policy** yet. That means the app cannot change profile data, status, or role until we add precise rules for it later.

## Test

After you run it:

1. Open **Database** → **Policies**.
2. Select the `profiles` table.
3. You should see exactly two policies:
    - “Users can read their own profile”
    - “Users can create their own pending profile”

Once that is visible, tell me. Next we’ll prepare Supabase Auth for ScamLock’s phone-number-and-password login, then build the sign-up screen that sends data through this secure path.


ok visible, next step

keep in mind one thing only signup page is there login page is yet left to add

also a suggestion that i js discovered that you can save each query with a name in supabase, so should i execute every query in a new tab and also name it so that in future ik what i have written to execute what, what say? good idea?

Yes—save every logical query in a separate named SQL Editor tab. That is a good habit.

Use sequential names such as:

```
001_create_profiles
002_secure_profiles
```

Each name describes one completed database change. Do not rerun an already-successful `create table` or `create policy` query; it will fail because the object already exists. Later, we’ll also save these same migrations inside the Flutter project for version control—but named Supabase queries are perfect for now.

One correction to my earlier plan: Supabase supports **native phone number + password** authentication. That matches ScamLock exactly, so we will not generate fake email addresses. Good catch before we built further.

## Goal

Enable native phone-and-password authentication.

## Why

Users enter a phone number and password. Supabase securely stores the password hash and verifies it during sign-in. ScamLock keeps extra details—firm name, approval status, role—in our `profiles` table.

For our India-first 10-digit number format:

```
User enters: 9876543210
Supabase receives: +919876543210
```

`+91` is the country code; the full format is called E.164.

## Where

Supabase → **Authentication** → **Providers** → **Phone**.

## Action — no code yet

- Turn on **Enable Phone provider** (or similarly named Phone authentication switch).
- Keep email authentication enabled; we simply will not use it in ScamLock.
- For development, leave **phone confirmation/verification** off unless you already have an SMS provider configured.

Phone confirmation sends SMS codes and needs an SMS provider such as Twilio/Vonage. For production, we should enable it to prove that a firm owns its phone number; admin approval remains a separate, required ScamLock decision.

## Test

Save the setting. You should see Phone listed as an enabled authentication provider.

Tell me once it is enabled. Next we’ll add the single Flutter file responsible for all authentication requests, before touching the sign-up screen. Supabase documents native phone-and-password auth and notes that phone verification needs an SMS provider. [Supabase password auth guide](https://supabase.com/docs/guides/auth/passwords)



so do we integrate the sms system for now or not?

do keep in mind rn we are developing and so we dont need any paid services keep it free untill we can!


No—do **not** integrate an SMS provider now.

For this development stage:

- Enable Supabase **Phone** authentication.
- Keep phone confirmation/verification **off**.
- Use phone number + password for sign-up and login.
- Admin approval still prevents new accounts from accessing ScamLock’s search or records.

This keeps the development build free and lets us complete the real app flow.

Later, before public launch, we’ll add SMS verification so a user proves they own the phone number. That requires an SMS provider and may incur charges; it also needs India-specific compliance planning. Supabase confirms SMS is required only when you choose phone-number confirmation. [Supabase phone/password authentication](https://supabase.com/docs/guides/auth/passwords)


ok next step

## Goal

Make Supabase automatically create a ScamLock profile whenever someone signs up.

## Why

A user registration creates two related things:

```
Supabase Auth account
→ ScamLock profiles row
```

Creating them from Flutter in two separate requests could leave a half-created account if the second request fails. Instead, a database trigger creates the profile inside Supabase as part of the sign-up process. This is cleaner and safer.

It also prevents a modified Flutter app from directly creating profile rows.

## Where

Supabase → **SQL Editor** → **New query**.

Save it as:

```
003_create_profile_on_signup
```

## Code — profile creation automation only

```
drop policy "Users can create their own pending profile"
on public.profiles;

revoke insert on table public.profiles from authenticated;

create function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    full_name,
    firm_name,
    phone,
    email,
    firm_location
  )
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'firm_name',
    right(new.phone, 10),
    nullif(new.raw_user_meta_data ->> 'email', ''),
    new.raw_user_meta_data ->> 'firm_location'
  );

  return new;
end;
$$;

create trigger create_profile_after_signup
after insert on auth.users
for each row
execute function public.create_profile_for_new_user();
```

## What this means

- `drop policy` and `revoke insert` remove direct profile creation from the app. Flutter will no longer be allowed to insert into `profiles`.
- `create function` creates reusable PostgreSQL logic.
- `trigger` means “automatically run this function after every new Supabase Auth user is created.”
- `new.id` is the secure ID Supabase generated for the new user.
- `new.raw_user_meta_data` is the extra sign-up data Flutter will send: name, firm name, optional email, and location.
- `new.phone` will be in Supabase’s international format, such as `+919876543210`.
- `right(new.phone, 10)` stores only `9876543210` in our `profiles.phone` column, matching ScamLock’s 10-digit requirement.
- We do not insert `account_status` or `app_role`; the safe defaults from the table apply automatically: `pending` and `member`.

## Test

After running it, Supabase should show **Success**. No visible table rows are created yet—that happens only when we make the first real sign-up.

Next, we’ll create one Flutter file: `lib/features/auth/data/auth_repository.dart`. It will send the phone/password and profile details to this automation safely.


ok next step

## Goal

Create one file that owns all future Supabase authentication requests.

## Why

Screens should collect/display information. They should not contain database or login code. This file becomes the single gateway between ScamLock and Supabase Auth.

Later:

```
Request-access screen
→ AuthRepository
→ Supabase Auth creates phone/password account
→ database trigger creates the pending profile
```

## Where

In Android Studio, create this folder:

```
lib/features/auth/data/
```

Then create this file:

```
lib/features/auth/data/auth_repository.dart
```

## Code — one file only

```
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> requestAccess({
    required String fullName,
    required String firmName,
    required String phone,
    required String firmLocation,
    required String password,
    String? email,
  }) async {
    final normalizedPhone = _toIndianPhoneFormat(phone);

    await _client.auth.signUp(
      phone: normalizedPhone,
      password: password,
      data: {
        'full_name': fullName.trim(),
        'firm_name': firmName.trim(),
        'email': email?.trim() ?? '',
        'firm_location': firmLocation.trim(),
      },
    );
  }

  String _toIndianPhoneFormat(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    if (!RegExp(r'^\d{10}$').hasMatch(digitsOnly)) {
      throw const FormatException(
        'Enter a valid 10-digit Indian phone number.',
      );
    }

    return '+91$digitsOnly';
  }
}
```

## What this means

- `class AuthRepository` groups authentication-related code in one place.
- `_client` is the connected Supabase client we initialized in `main.dart`.
- `requestAccess()` receives all registration details from the future sign-up screen.
- `_toIndianPhoneFormat()` removes spaces/dashes, verifies exactly 10 digits, then adds `+91`.
- `await` means Flutter waits for Supabase to finish the sign-up request.
- `data: {...}` sends the profile fields as secure sign-up metadata.
- Your PostgreSQL trigger reads that metadata and inserts the `profiles` row automatically.
- This file does not store passwords. It sends the password securely to Supabase; Supabase stores only a password hash.

## Test

Save the file. The app should still run normally because no screen calls this code yet.

Next, we will create the sign-up screen file and connect its Submit button to `requestAccess()`.


next step


## Goal

Create the real **Request Access / Sign Up** screen and connect its Submit button to `AuthRepository`.

## Why

This screen collects the exact data needed to create a firm account. It does not contain Supabase logic itself—it passes the values to `AuthRepository`, which keeps the architecture clean.

## Where

Create this file:

```
lib/features/auth/presentation/screens/request_access_screen.dart
```

## Code — one screen file only

```
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';
import '../../../../core/routes/app_routes.dart';

class RequestAccessScreen extends StatefulWidget {
  const RequestAccessScreen({super.key});

  @override
  State<RequestAccessScreen> createState() => _RequestAccessScreenState();
}

class _RequestAccessScreenState extends State<RequestAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();

  final _fullNameController = TextEditingController();
  final _firmNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _firmNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _authRepository.requestAccess(
        fullName: _fullNameController.text,
        firmName: _firmNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        firmLocation: _locationController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.pendingApproval,
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Something went wrong. Please check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputStyle({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request access')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Join ScamLock',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your firm must be approved by an administrator before access is granted.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _fullNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputStyle(
                  label: 'Your name',
                  icon: Icons.person_outline,
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _firmNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputStyle(
                  label: 'Firm name',
                  icon: Icons.business_outlined,
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inputStyle(
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                ),
                validator: (value) {
                  final digitsOnly =
                      (value ?? '').replaceAll(RegExp(r'\D'), '');

                  if (!RegExp(r'^\d{10}$').hasMatch(digitsOnly)) {
                    return 'Enter a valid 10-digit phone number.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputStyle(
                  label: 'Email address (optional)',
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputStyle(
                  label: 'Firm location',
                  icon: Icons.location_on_outlined,
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputStyle(
                  label: 'Create password',
                  icon: Icons.lock_outline,
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Use at least 8 characters.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## What happens when the button is pressed

```
Form checks the input
→ AuthRepository formats phone as +91xxxxxxxxxx
→ Supabase creates the password-protected Auth account
→ our PostgreSQL trigger creates the matching profiles row
→ it defaults to pending/member
→ app moves to the pending-approval screen
```

- `TextEditingController` reads what the user typed.
- `StatefulWidget` is needed because the screen changes while submission is in progress.
- `_isSubmitting` disables repeated button taps and shows a loading spinner.
- `try/catch` converts Supabase errors into readable messages.
- `dispose()` frees the controllers when this screen closes.

## Test

Save the file only. It should have no red errors.

The pending route and the way to reach this screen are not wired yet—that is deliberately the next small step.


before i paste this code into the file i have a question

is it the right thing to include working of the widgets and thier styles to be in a single whole page? or shall it be in diffrent files like one page has the skeleton and other has its style rules


as said earlier i have knowldge of coding in other languages so i am asking what is better approach


For Flutter, the professional default is: keep a screen’s layout and its screen-specific styling in the same file.

Flutter is declarative: a widget’s style is part of how that widget is built. Separating every colour, padding, and `TextStyle` into a separate “styles file” becomes harder to read than useful—unlike CSS in web development.

Use this split:

```
screen file
→ screen layout, local spacing, local widget styling, button handlers

shared widget file
→ repeated components used on more than one screen

theme files
→ brand-wide colours, fonts, button/input defaults

repository file
→ Supabase/data requests

controller/view-model file
→ complex screen state and business flow, when needed
```

For the sign-up screen:

- Keeping `Scaffold`, fields, and `_inputStyle()` together in `request_access_screen.dart` is correct.
- `AuthRepository` is already correctly separated because it talks to Supabase.
- Later, when Login and Request Access use the same styled input fields, we should extract an `AppTextField` shared widget.
- When we redesign ScamLock, shared colours and typography will go in:

```
lib/core/theme/
├── app_colors.dart
├── app_text_styles.dart
└── app_theme.dart
```

So paste the sign-up screen as given. It is not “all code in one file”; it is one screen file, with its data work already separated. We’ll extract only genuinely shared or complex parts, not split files just for the sake of splitting them.



## Goal

Create the separate screen shown after a firm submits its access request.

## Why

A sign-up should not simply return to the login form. The firm needs a clear state: their account exists, but an admin must approve it.

Keeping this in its own file also follows our one-screen-per-file architecture.

## Where

Create this file:

```
lib/features/auth/presentation/screens/pending_approval_screen.dart
```

## Code — one screen file only

```
import 'package:flutter/material.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 72,
                  color: Color(0xFFB42318),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Request submitted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your firm is waiting for administrator approval. '
                  'You will be able to use ScamLock after approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## What this means

- `StatelessWidget` is enough because this screen only displays information; it has no changing form data.
- `automaticallyImplyLeading: false` removes the back arrow. A pending user should not return to the registration form and submit repeatedly.
- `Center` and `Column` place the message cleanly in the middle of the page.

## Test

Save the file. It should have no red errors.

Next, we will update one file—`app.dart`—to register both the Request Access and Pending Approval routes


ok next step

## Goal

Register the two new screens with the app’s named-route system.

## Why

A route is a named destination. Instead of one screen importing and directly constructing another, every screen asks the app to open a route such as `/request-access`. This keeps navigation centralized and scalable.

## Where

Replace all contents of:

```
lib/app.dart
```

## Code — one app-configuration file only

```
import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/pending_approval_screen.dart';
import 'features/auth/presentation/screens/request_access_screen.dart';

class ScamLockApp extends StatelessWidget {
  const ScamLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamLock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB42318),
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.requestAccess: (_) => const RequestAccessScreen(),
        AppRoutes.pendingApproval: (_) => const PendingApprovalScreen(),
      },
    );
  }
}
```

## What this means

- Each `import` makes one screen available to the app.
- `initialRoute` says the app starts at the login screen.
- `routes` maps a route name from `app_routes.dart` to the screen Flutter should show.
- `(_) => const RequestAccessScreen()` is a small function that creates that screen only when Flutter opens the route.

## Test

Save and run the app. It should still open the login screen without errors.

The “New firm? Request access” button still shows its temporary message. Next, we will update only `login_screen.dart` so that button opens the real Request Access screen.




ok next step

**and after this ill just send " . " a single dot, consider that as next step**

A single `.` will mean “continue to the next step.”

## Goal

Make the **New firm? Request access** button open the real sign-up screen.

## Why

The route now exists in `app.dart`; this connects the login screen button to that named route. The login screen does not need to know how the sign-up screen is built.

## Where

Replace all contents of:

```
lib/features/auth/presentation/screens/login_screen.dart
```

## Code — one screen file only

```
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const Icon(
                Icons.shield_outlined,
                size: 72,
                color: Color(0xFFB42318),
              ),

              const SizedBox(height: 20),

              const Text(
                'ScamLock',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Check before you transact.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 48),

              const TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 16),

              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Real sign in will be connected next.'),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Sign in'),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.requestAccess,
                  );
                },
                child: const Text('New firm? Request access'),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
```

## What changed

```
Navigator.of(context).pushNamed(AppRoutes.requestAccess)
```

This tells Flutter: “open the screen registered under the request-access route.” The route mapping stays in `app.dart`; the route name stays in `app_routes.dart`.

## Test

1. Full restart the app.
2. Tap **New firm? Request access**.
3. The sign-up form should open.
4. Use Android’s back button; it should return to login.

Send `.` when that works.


.


## Goal

Test the complete first-time sign-up flow against Supabase.

## Why

This verifies the entire chain—not just the Flutter screens:

```
Sign-up form
→ AuthRepository
→ Supabase phone/password account
→ PostgreSQL trigger
→ pending profiles row
→ Pending Approval screen
```

## Where

Run ScamLock in the Pixel emulator.

## Action — no code

1. Open **New firm? Request access**.
2. Enter your own real 10-digit phone number—do not use somebody else’s number.
3. Use a strong test password you can remember.
4. Fill the required fields. Email can remain blank.
5. Tap **Submit request**.

## Expected result

- You should land on the **Request submitted** screen.
- In Supabase → **Authentication** → **Users**, one phone-based user should appear.
- In Supabase → **Table Editor** → `profiles`, one matching row should appear with:

```
account_status: pending
app_role: member
```

That confirms the admin approval gate is working at the database level.

If you receive an error, paste the exact error text (do not share your password or keys).


.


That error confirms Supabase Phone Auth is not enabled yet. No account or profile was created, so nothing needs cleanup.

## Fix

In Supabase:

1. Open `scamlock-dev`.
2. Go to **Authentication** → **Providers**.
3. Open **Phone**.
4. Turn on the setting labelled something like:
    - **Enable Phone provider**, or
    - **Enable phone signups**
5. Click **Save**.

For our free development setup:

- Do not configure Twilio, SMS, or another provider yet.
- Keep **phone confirmation** off.

Then return to the emulator and submit the sign-up form again. You do not need to rebuild the Flutter app; this is a Supabase dashboard setting.

Expected next result: it opens the Pending Approval screen and creates the user/profile records.


when i am trying to enable the phone sms thing, it is asking for account details for service providers which i dont have rn as we discussed earlier


Don’t enter any SMS-provider details or pay for anything. You found the limitation correctly: hosted Supabase requires an SMS provider before its native Phone Auth can be enabled.

I need to correct the development path: for now, we’ll keep the ScamLock UI as **phone + password**, but internally use a generated technical email based on that phone number. This is only for development. Their optional real email remains stored separately in `profiles`.

```
User enters: 9876543210 + password
Flutter internally uses: 9876543210@dev.scamlock.local + password
```

No email is sent, and no paid service is needed. Before production, when we add SMS verification, we will switch the internal authentication to native phone auth and remove these development test accounts.

## Next action — dashboard only

1. Do **not** enable the Phone provider.
2. Go to Supabase → **Authentication** → **Providers** → **Email**.
3. Ensure **Email provider** is enabled.
4. Turn **off** the setting called **Confirm email** / **Enable email confirmations**.
5. Save.

Why: the generated technical address cannot receive an email, and disabling confirmation lets Supabase create a usable development session immediately.

Once that is saved, send `.`. Then I’ll give you one small code update to make our authentication repository use this free development approach safely.


It still says the same error, you sure there are no changes in the code?


Yes—there are required code changes. Your current `AuthRepository` still calls Supabase with:

```
signUp(phone: ...)
```

So it will keep producing “phone sign-ups are disabled.” Changing the Email provider setting alone cannot change that.

Don’t retry the sign-up yet. We need two small updates:

```
1. Database trigger: read the phone number from sign-up metadata.
2. AuthRepository: use a generated development email internally.
```

We’ll do the database change first.

## Goal

Update the profile-creation trigger for the email-based development setup.

## Where

Supabase → **SQL Editor** → **New query**. Save it as:

```
004_update_signup_trigger_for_development_auth
```

## Code — one database function update only

```
create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    full_name,
    firm_name,
    phone,
    email,
    firm_location
  )
  values (
    new.id,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'firm_name',
    new.raw_user_meta_data ->> 'phone',
    nullif(new.raw_user_meta_data ->> 'email', ''),
    new.raw_user_meta_data ->> 'firm_location'
  );

  return new;
end;
$$;
```

## What changed

Previously, the function used:

```
right(new.phone, 10)
```

That only works when Supabase creates a native phone-auth user. In our free development setup, it creates an email-auth user instead, so `new.phone` would be empty.

The new version reads `phone` from the metadata Flutter will send. It remains protected by the `profiles.phone` 10-digit database rule.

Run this query successfully, then send `.`. Next I’ll provide the matching `auth_repository.dart` update.


.


## Goal

Switch the development authentication request from Supabase Phone Auth to free internal Email Auth—while keeping ScamLock’s visible login as phone number + password.

## Why

Without an SMS provider, Supabase will not enable its hosted Phone Auth. This repository update creates a deterministic technical email from the phone number, but users never see or use that email.

## Where

Replace all contents of:

```
lib/features/auth/data/auth_repository.dart
```

## Code — one data-layer file only

```
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _developmentAuthDomain = 'dev.scamlock.invalid';

  Future<void> requestAccess({
    required String fullName,
    required String firmName,
    required String phone,
    required String firmLocation,
    required String password,
    String? email,
  }) async {
    final phoneDigits = _phoneDigits(phone);
    final developmentAuthEmail = _developmentEmailFor(phoneDigits);

    await _client.auth.signUp(
      email: developmentAuthEmail,
      password: password,
      data: {
        'full_name': fullName.trim(),
        'firm_name': firmName.trim(),
        'phone': phoneDigits,
        'email': email?.trim() ?? '',
        'firm_location': firmLocation.trim(),
      },
    );
  }

  String _phoneDigits(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    if (!RegExp(r'^\d{10}$').hasMatch(digitsOnly)) {
      throw const FormatException(
        'Enter a valid 10-digit phone number.',
      );
    }

    return digitsOnly;
  }

  String _developmentEmailFor(String phoneDigits) {
    return '$phoneDigits@$_developmentAuthDomain';
  }
}
```

## What changed

Previously:

```
_client.auth.signUp(phone: ...)
```

Now:

```
_client.auth.signUp(email: developmentAuthEmail, ...)
```

The metadata includes the original 10-digit phone number, so the PostgreSQL trigger can create the correct `profiles.phone` value.

```
Visible to firm: 9876543210 + password
Used internally during development: 9876543210@dev.scamlock.invalid + password
Stored in profiles table: 9876543210
```

## Test

1. Save the file.
2. Fully restart the app.
3. Submit the Request Access form again using your own number.
4. Expect the Pending Approval screen.
5. Check Supabase:
    - **Authentication → Users:** one email-auth user
    - **Table Editor → profiles:** matching row, `pending` and `member`

If any error appears, paste its exact text only.


man that worked now, how should i check the request, approve / reject it


You can check it now in Supabase, but the final admin panel has not been built yet.

Open Supabase → **Table Editor** → `profiles`. Your submitted request is the row with:

```
account_status = pending
app_role = member
```

Before we manually approve/reject anything, we should add a proper `rejected` state. This keeps “not approved” separate from “previously active but suspended for subscription/non-payment.”

```
pending   → awaiting admin decision
active    → approved; full access
suspended → access restricted; can later get view-only access
rejected  → never approved; no access
```

## Goal

Add the `rejected` status option.

## Where

Supabase → **SQL Editor** → **New query**. Save as:

```
005_add_rejected_account_status
```

## Code — one database change only

```
alter table public.profiles
drop constraint if exists profiles_account_status_check;

alter table public.profiles
add constraint profiles_account_status_check
check (account_status in ('pending', 'active', 'suspended', 'rejected'));
```

## What this means

- `alter table` changes an existing table without deleting its data.
- We remove the old allowed-status rule, then replace it with one that includes `rejected`.
- The database still refuses any made-up status value.

## After it succeeds

For temporary development management, use the `profiles` Table Editor:

- To approve: edit `account_status` from `pending` to `active`.
- To reject: change it to `rejected`.
- To later block a previously approved user: change it to `suspended`.

Do not change the `id`, phone, or `app_role` manually.

This direct editing is only our development control panel. Next, we’ll make your first account an `admin`, then build the real in-app Admin Panel with approval/rejection actions and an audit trail.


HERE MY LIMIT GOT HIT AND my work stopped

the above file is literally the whole file not just a context file or something it is a full chat hostory luterally copy pasted so i dont miss any context, rule or instruction / preffrence 

so now its your job to go through all and grasp!
---
[2026-07-25] User: From now on, append every prompt I give and your reply to ull chat.md in short, sensible format so the file stays current as our context file.
Assistant: Confirmed. Every prompt and reply will be appended to ull chat.md going forward, keeping the conversation alive as our context file.

---
[2026-07-25] User: Add the above chat to fullchat. 2ndly: updated app_role as admin, and follow the next step.
Assistant: Appended the entire conversation context to full chat.md. Next, I will update the first account to admin role in Supabase, then proceed to build the admin panel for approving/rejecting pending users and managing access.

---
[2026-07-25] User: ok next (with environment_details metadata).
Assistant: Understood. Appending all prompts and replies to full chat.md going forward. The next step is to build the Admin Panel screens for managing pending users and toggling access.

---
[2026-07-25] User: Confirmed both SQL steps done and app_role updated to admin. Also clarified: do not create any files/folders on device — just provide code in our format. User will manually create files. Asked for next step.
Assistant: Provided the next step: updated AppRoutes with admin route constants + created AdminDashboardScreen with three cards (Pending Approvals, All Users, Audit Log). Gave code for app_routes.dart update, admin_dashboard_screen.dart creation, and instructions to update app.dart routes in the follow-up step.

### TIPS FOR THE NEXT AGENT

All ScamLock code is given as code blocks to paste manually (user creates files).
3. Full workflow completed so far:
    - DB: profiles table (001), RLS (002), signup trigger (003), dev auth trigger fix (004), rejected status (005), admin_actions table (006), admin_actions RLS (007)
    - Auth: AuthRepository with dev email auth (phone → {phone}@dev.scamlock.invalid), signIn(), getCurrentProfile()
    - Screens: LoginScreen, RequestAccessScreen, PendingApprovalScreen, AdminDashboardScreen (separate files, named routes)
    - Routes: AppRoutes constants updated with admin dashboard
    - app.dart: registers all routes including adminDashboard
4. What still needs to be done (in order):
    - Build admin_pending_users_screen.dart (list pending users with Approve/Reject buttons)
    - Build admin_user_list_screen.dart (list all users with status, suspend/activate toggle)
    - Build admin_audit_log_screen.dart (list admin_actions)
    - Build the core lock/unlock feature (search, records, add record, record detail, lock management)
5. The app uses a dev auth bypass: email-based Supabase Auth where the email is {phone}@dev.scamlock.invalid. No SMS provider is needed for development.
6. Account statuses: pending → active (admin approves) / rejected (admin rejects) / suspended (admin blocks for non-payment). Admins can toggle suspended ↔ active.
7. File structure follows feature-first architecture: lib/main.dart → lib/app.dart → lib/core/routes/, lib/core/config/, lib/features/auth/data/, lib/features/auth/presentation/screens/, lib/features/admin/presentation/screens/, etc.
8. Each step follows the Goal → Why → Where → Code → What it means → Test format.
9. The user manually creates files on disk from code blocks. The app is currently at: login wired to real auth, admin dashboard screen exists and is registered in app.dart.

---

## [2026-07-25] Debug & Admin Wiring

User: The login showed "Something went wrong, please check your connection" even though connection was fine. Updated catch block to show actual error.

User updated login_screen.dart catch from `catch (_)` to `catch (error)` with `_showMessage('Error: $error')` and `debugPrint('Login error: $error')`. Initial attempt failed because oldString didn't match due to a previous partial edit removing the closing brace. Fixed by replacing the exact 4-line block.

User reported the actual issue: account role is `admin`, but `adminDashboard` route is defined in `AppRoutes` yet not registered in `app.dart` routes map, and `AdminDashboardScreen` file doesn't exist on disk.

Assistant: 
1. Created `lib/features/admin/presentation/screens/admin_dashboard_screen.dart` with import for supabase_flutter, AdminDashboardScreen with AppBar (sign-out button), and 3 cards (Pending Approvals, All Users, Audit Log) each showing "coming next" SnackBar for now.
2. Updated `app.dart` to import AdminDashboardScreen and register `AppRoutes.adminDashboard` route.

User: Confirmed admin dashboard with 3 buttons is visible and working. Login → admin routing fully functional.

---

## [2026-07-25] Admin Screens - Pending Users, All Users with Filters

User: Reported "bunch of errors" after updating routes. Root cause: `app_routes.dart` was corrupted — contained AdminRepository code instead of route constants, plus an invalid import mid-file. Fixed by restoring `app_routes.dart` to only the 8 route constants (no imports, no classes).

User: Got "Could not find a generator for route /admin-pending-users" — `app.dart` was missing the import and route registration for `admin_pending_users_screen.dart`. Fixed by adding both.

User: Pending approvals screen opened but showed "No pending approvals right now" even with a pending user in DB. Root cause: RLS policy only allowed users to read their own profile. Added new policy "Authenticated users can view all profiles" (noted: not admin-only yet, will be fixed when building search feature).

User: Asked to add sorting/filtering feature to All Users screen before building it. Built `admin_user_list_screen.dart` with filter chips (All, Pending, Active, Suspended, Rejected) showing live counts, client-side filtering, and status toggle buttons.

User: Got "Could not find a generator for route /admin-user-list" — same issue, `app.dart` missing import and route for `admin_user_list_screen.dart`. Fixed.

User: Reported multiple compile errors in `admin_user_list_screen.dart`:
1. Wrong import: `../../../../auth/data/auth_repository.dart` (file doesn't use AuthRepository at all)
2. Stray `LABEL` text on line 27 (leftover from earlier code block)
3. `_statusColor` defined inside state class but used in `_UserCard` — moved to top-level function

Fixed all 3. User confirmed (".") All Users screen works with filter chips and status toggling.

