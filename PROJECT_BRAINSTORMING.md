# CleanNow Project Brainstorming

## 1. Project Identity

**Project name:** CleanNow  
**Project type:** Cleaning service booking and management system  
**Platforms:** Web and mobile through Flutter  
**Primary users:** Customers, cleaners, and administrators  
**Initial market assumption:** Urban households, apartments, and small offices, with Phnom Penh as a suitable pilot location  
**Project stage:** University/demo system with a working full-stack prototype

### One-sentence concept

CleanNow is a shared platform where customers can book trusted cleaning services, cleaners can manage assigned jobs, and administrators can coordinate the complete business operation.

### Short elevator pitch

Finding and organizing a cleaner often depends on phone calls, social-media messages, unclear prices, and manual schedules. CleanNow puts the process into one application. Customers receive transparent service choices and live booking progress, cleaners receive organized job information, and administrators receive the tools needed to manage services, staff, assignments, and revenue.

## 2. Brainstorming Question

> How might we make booking, delivering, and managing a cleaning service simple, transparent, and reliable for everyone involved?

This question creates three connected areas to explore:

1. How can customers book confidently and quickly?
2. How can cleaners clearly understand and complete their work?
3. How can administrators control daily operations without manual paperwork?

## 3. Problem Statement

Traditional cleaning-service arrangements commonly have these problems:

- Customers must call or message several providers to ask about price and availability.
- Service packages and final prices may be unclear before the job begins.
- Addresses, instructions, and preferred schedules can be recorded incorrectly.
- Customers cannot easily see whether a cleaner is assigned or on the way.
- Cleaners may receive incomplete job information or conflicting schedules.
- Cleaning businesses manually track staff, bookings, payments, and performance.
- There may be limited proof of completed work or a structured review process.
- Business owners have difficulty understanding revenue and popular services.

CleanNow addresses these problems through a structured digital workflow and one shared source of booking information.

## 4. Vision, Mission, and Value

### Vision

To make professional cleaning services accessible, trustworthy, and easy to coordinate through technology.

### Mission

To connect customers, cleaners, and cleaning-business administrators in one system that supports service discovery, booking, assignment, job tracking, completion evidence, and feedback.

### Core values

- **Convenience:** Minimize the time and effort required to arrange a cleaning.
- **Transparency:** Show service details, prices, assignments, and progress clearly.
- **Trust:** Support verified cleaner profiles, reviews, and task documentation.
- **Fairness:** Give cleaners clear schedules, job expectations, and pay information.
- **Control:** Give administrators accurate operational and financial information.

## 5. Project Goals

### Primary goal

Build an end-to-end cleaning-service workflow that every role can use from the first booking request through job completion and review.

### Supporting goals

- Provide clear service descriptions and automatic price calculation.
- Reduce communication mistakes through structured booking forms.
- Help administrators assign only suitable and available cleaners.
- Allow customers to follow meaningful booking status changes.
- Allow cleaners to document work with notes and before/after photos.
- Store shared business data for reporting and future analysis.
- Provide a responsive experience on web and mobile devices.

## 6. Target Users and Personas

### Persona A: Customer

**Example:** Dara, a busy apartment resident  
**Needs:** A reliable cleaner, visible prices, flexible scheduling, and fast booking  
**Frustrations:** Repeating details by phone, uncertain arrival times, and unclear quality  
**CleanNow value:** Dara can select a service, enter the property details, see the calculated total, follow progress, and leave a review.

### Persona B: Cleaner

**Example:** Sreypov, an independent cleaning professional  
**Needs:** A clear work schedule, complete customer instructions, and transparent job status  
**Frustrations:** Last-minute calls, missing addresses, overlapping jobs, and unclear pay  
**CleanNow value:** Sreypov can see assigned work, update progress, document completion, and review performance and earnings.

### Persona C: Administrator

**Example:** Vannak, a cleaning-service manager  
**Needs:** One place to manage requests, workers, services, assignments, and revenue  
**Frustrations:** Spreadsheet errors, manual coordination, and limited business visibility  
**CleanNow value:** Vannak can manage accounts and services, approve cleaner applications, assign jobs, monitor operations, and review financial reports.

## 7. Proposed Solution

CleanNow contains three connected portals:

| Portal | Main purpose | Important capabilities |
| --- | --- | --- |
| Customer | Find and request cleaning | Browse services, configure a booking, see pricing, track status, manage favorites and addresses, review work |
| Cleaner | Receive and complete work | View schedule, open job details, update job progress, attach photos and notes, manage availability |
| Administrator | Operate the business | Manage users, cleaners, applications, services, bookings, assignments, revenue, and reports |

### Central service workflow

```text
Customer chooses a service
          ↓
Customer enters date, address, property, extras, and payment method
          ↓
System calculates the price and creates a Pending booking
          ↓
Administrator reviews, accepts, and assigns an available cleaner
          ↓
Cleaner updates: On the Way → Arrived → In Progress → Completed
          ↓
Customer reviews the completed service
          ↓
Administrator uses the result for operational and financial reporting
```

## 8. Feature Brainstorm

### Customer features

- Registration, login, logout, and password-reset request
- Service search, categories, filters, sorting, and favorites
- Detailed service descriptions, tasks, duration, price, and rating
- Booking date, time, address, property size, extras, and instructions
- Automatic price and estimated-duration calculation
- Cash and configured KHQR payment choices
- Booking history, assignment information, and status timeline
- Cancellation for eligible bookings
- Saved addresses and notifications
- Rating and written feedback after completion
- Cleaning products, tips, and promotions

### Cleaner features

- Cleaner application and administrator approval
- Cleaner dashboard with upcoming and active work
- Calendar and schedule view
- Full customer address, instructions, and service-task details
- Controlled job-status progression
- Before/after photos and completion notes
- Availability control when the cleaner has no active job
- Performance, reviews, achievements, and pay summaries

### Administrator features

- Operational dashboard with important totals
- Customer and staff account management
- Cleaner application review and approval
- Cleaner activation, availability, skills, and hourly-rate management
- Cleaning-service package management
- Booking acceptance, rejection, cancellation, and assignment
- Revenue, cleaner-pay, and service-performance summaries
- Exportable reports

## 9. Scope Definition

### Present prototype scope

The current prototype includes:

- Flutter interfaces for customer, cleaner, and administrator roles
- Provider-based application state and repository-based data access
- A Python REST API with SQLite locally and Turso-compatible deployment support
- Services, users, bookings, cleaner applications, assignments, reviews, favorites, addresses, notifications, and products
- Vercel deployment configuration for the web application and backend API
- Automated Flutter unit and widget tests

### Intentionally outside the current production scope

- Real-money payment processing and payment verification
- Production-grade access tokens and server-side authorization for every protected operation
- Government identity or background-check integrations
- Real-time GPS tracking
- Automated SMS, email, and push-notification delivery
- Refunds, disputes, insurance, and formal service guarantees
- Advanced cleaner matching or route optimization

These are future opportunities, not claims about the current prototype.

## 10. Functional Requirements

The system should allow:

1. A user to register and sign in with an assigned role.
2. A customer to view active services and their pricing information.
3. A customer to submit a valid future booking.
4. The system to calculate the total from the base service, property size, and extras.
5. An administrator to accept or reject a pending request.
6. An administrator to assign an active, available cleaner.
7. A cleaner to view only relevant assigned jobs.
8. A cleaner to follow valid status transitions in order.
9. A cleaner to attach completion documentation.
10. A customer to view their own booking history and progress.
11. A customer to submit one review for eligible completed work.
12. An administrator to view operational and financial summaries.

## 11. Non-Functional Requirements

- **Usability:** Important actions should be understandable without training.
- **Responsiveness:** Screens should work on narrow mobile and wider web layouts.
- **Reliability:** Booking and status data should remain consistent across roles.
- **Performance:** Common lists and actions should respond quickly under normal demo usage.
- **Maintainability:** Interface, state, repositories, API, and storage should remain separated.
- **Security:** Production use requires secure authentication, authorization, secret management, validation, and encrypted transport.
- **Privacy:** Personal data and cleaner documents should only be available to authorized users.
- **Accessibility:** Text, contrast, touch targets, validation messages, and keyboard navigation should support a broad range of users.

## 12. Product Differentiators

Potential reasons to choose CleanNow instead of arranging work through chat or phone calls:

- One connected workflow for customers, cleaners, and managers
- Transparent pricing before booking submission
- Cleaner assignment and step-by-step job tracking
- Before/after task documentation
- Cleaner availability and schedule management
- Local payment relevance through optional KHQR presentation
- Business reporting built from actual booking activity
- A single Flutter codebase for web and mobile experiences

## 13. Business and Revenue Ideas

Possible business models for a future commercial version include:

- Commission charged on each successfully completed booking
- Fixed service margin between the customer price and cleaner pay
- Monthly subscription for cleaning companies using the management platform
- Featured placement for service packages or cleaning products
- Recurring household or office cleaning plans
- Additional fees for urgent, holiday, or after-hours requests

The recommended starting model is a clear commission or service margin because it directly follows completed work and is easy to explain.

## 14. Success Metrics

### Customer metrics

- Percentage of visitors who complete a booking
- Average time required to make a booking
- Repeat-booking rate
- Cancellation rate
- Average rating and customer complaint rate

### Cleaner metrics

- Booking acceptance and completion rates
- On-time arrival rate
- Average customer rating
- Cleaner utilization and active hours
- Cleaner retention

### Business metrics

- Completed bookings per week or month
- Gross booking value and net revenue
- Average booking value
- Most popular service categories
- Time from booking submission to cleaner assignment
- Customer acquisition and retention rates

### Prototype success criteria

- Every role can complete its part of the main workflow.
- Shared changes appear correctly for the other roles.
- Invalid inputs and invalid status transitions are rejected.
- The application works on a narrow mobile viewport and the web.
- Automated analysis and tests pass before demonstration.

## 15. Risks and Mitigation Ideas

| Risk | Possible impact | Mitigation idea |
| --- | --- | --- |
| Weak authorization | Users could access or change unauthorized data | Add access tokens and enforce role and ownership checks in the API |
| Unverified cleaners | Customer safety and trust concerns | Add identity review, references, background checks, and approval records |
| Schedule conflicts | Late or missed services | Add server-side availability checks, travel buffers, and calendar conflict detection |
| Payment fraud or failure | Lost revenue and disputes | Integrate a verified payment provider with server-side confirmation |
| Incorrect addresses | Delays and failed jobs | Add maps, address validation, pins, and contact confirmation |
| Poor service quality | Low retention and reputation damage | Use checklists, photos, reviews, support cases, and quality audits |
| Personal-data exposure | Legal and trust damage | Minimize collected data, encrypt sensitive values, and apply strict access controls |
| Serverless/database limitations | Slow requests or connection failures | Monitor errors, reuse supported database connections, and load-test deployment |

## 16. Development Roadmap

### Phase 1: Prototype foundation — implemented

- Role-based Flutter portals
- Service discovery and booking
- Admin booking and cleaner management
- Cleaner tracking workflow
- Reviews, notifications, products, and reporting
- Python API and shared database

### Phase 2: Security and deployment readiness — next priority

- Issue secure authentication tokens
- Enforce server-side roles and record ownership
- Validate all API inputs consistently
- Protect cleaner documents and uploaded photos
- Add backend automated tests, logging, and monitoring
- Confirm Turso and Vercel behavior under realistic requests

### Phase 3: Real business operation

- Integrate a production payment provider
- Add email, SMS, or push notifications
- Add maps, location pins, and travel estimates
- Add recurring bookings and discount codes
- Create support, refund, and dispute workflows
- Add cleaner verification and service-quality controls

### Phase 4: Growth and intelligence

- Recommend services from customer history
- Automatically suggest the best cleaner by schedule, skills, rating, and distance
- Forecast busy periods and staffing requirements
- Optimize multi-job routes
- Provide advanced business analytics
- Support multiple branches, languages, and currencies

## 17. Technology Direction

| Area | Current choice | Reason |
| --- | --- | --- |
| Client | Flutter and Dart | One responsive codebase for web and mobile |
| UI state | Provider | Simple state sharing across role-based screens |
| Network | Dio | Structured REST requests and error handling |
| Backend | Python | Accessible implementation for a university prototype |
| Local database | SQLite/sqflite | Lightweight relational storage and offline fallback |
| Hosted database | Turso/libSQL | SQLite-compatible database suitable for serverless access |
| Hosting | Vercel | Web and serverless API deployment from GitHub |
| Documentation | OpenAPI and Swagger | Discoverable and testable endpoint definitions |

## 18. Research and Validation Plan

Before treating CleanNow as a commercial product, interview at least:

- 5–10 people who have previously hired a cleaner
- 3–5 cleaners or cleaning staff
- 2–3 cleaning-business managers

Suggested interview questions:

1. How do you currently arrange or receive cleaning work?
2. What information is commonly missing or misunderstood?
3. What makes you trust or reject a provider?
4. Which part of scheduling causes the most difficulty?
5. How do you decide whether a price is fair?
6. Which progress updates are actually useful?
7. Would before/after photos improve trust or create privacy concerns?
8. Which payment methods do you prefer?
9. What would make you use the service repeatedly?

Use the answers to revise the feature priority rather than assuming every brainstormed feature is necessary.

## 19. Open Questions

- Is CleanNow the cleaning provider, or a marketplace connecting independent cleaners?
- Who is responsible for damage, cancellation, refunds, and customer support?
- How should cleaner pay and platform commission be calculated?
- Should customers choose a specific cleaner or allow automatic assignment?
- Which locations and service types should be supported first?
- How far in advance can customers book or cancel?
- What proof is required before approving a cleaner?
- Should photos be mandatory, optional, or restricted for privacy?
- Which languages and currencies are required for the first real market?
- What data-retention period is appropriate for accounts, bookings, and photos?

## 20. Recommended Project Definition

For the current academic project, use this final definition:

> **CleanNow is a web and mobile cleaning service booking and management system designed for customers, cleaners, and administrators. It digitalizes service discovery, price calculation, booking, cleaner assignment, job tracking, completion documentation, reviews, and business reporting. The project demonstrates how a shared full-stack system can reduce manual coordination and improve transparency across the complete cleaning-service workflow.**

## 21. Suggested Presentation Summary

When presenting the project, explain it in this order:

1. **Problem:** Cleaning bookings are often manually coordinated and unclear.
2. **Users:** Customers, cleaners, and administrators have different but connected needs.
3. **Solution:** CleanNow gives each role a dedicated portal using shared booking data.
4. **Demonstration:** Customer books, admin assigns, cleaner completes, customer reviews.
5. **Technology:** Flutter, Provider, Dio, Python REST API, SQLite/Turso, and Vercel.
6. **Value:** Faster booking, clearer operations, better tracking, and useful business data.
7. **Limitation:** Security and real payments must be strengthened before production use.
8. **Future:** Verified payments, notifications, maps, recurring bookings, and intelligent matching.

