1.	Introduction
1.1	Purpose 
This SRS document describes the complete software requirements for Zovetica, a mobile application developed using Flutter for helping pet owners manage their pets’ health, book veterinary appointments, access emergency guides, and interact with a pet community. This document covers all functional, non-functional, interface, and environmental requirements needed for the development of the application.
1.2	Document Conventions
• Headings follow IEEE SRS structure.
• Functional requirements are labeled as REQ-Fx.
• Non-functional requirements are labeled as REQ-NFx.
• All high-priority items are marked explicitly inside sections.
• Technical terms are defined in the glossary.

1.3	Intended Audience and Reading Suggestions
This document is intended for:
• Developers and mobile engineers
• Project supervisors and evaluators
• Testers and QA engineers
• Veterinary professionals (future stakeholders)
Readers should begin with the introduction, then review the overall description, followed by detailed system features, and lastly non-functional requirements.
1.4	Product Scope
Zovetica is a pet healthcare app designed to solve the major problems faced by pet owners in Pakistan, where no centralized platform currently exists for managing veterinary care. The system enables pet owners to book veterinary appointments, check doctor availability, receive medication reminders, access offline first-aid emergency guidance, and participate in a community forum for shared learning.
In addition to helping pet owners, Zovetica also provides significant benefits to veterinary doctors. Many pet doctors in Pakistan struggle to reach new patients and manage their appointments effectively due to the lack of digital exposure. Zovetica offers them a dedicated platform where they can showcase their qualifications, manage appointment schedules, and connect with a wider audience of pet owners. This not only increases their professional visibility but also helps reduce appointment gaps and improves their overall practice efficiency.
The overall goal of Zovetica is to digitalize pet health management for both owners and doctors, reduce delays in treatment, streamline communication, and create a reliable ecosystem for pet healthcare in Pakistan.
1.5	References
• IEEE SRS Template – Karl E. Wiegers
• Flutter Documentation – flutter.dev
• Firebase Documentation – firebase.google.com
• Pakistan Pet Care Market Reports (informal online sources)
2.	Overall Description
2.1	Product Perspective
Zovetica is a new standalone mobile application. It integrates Supabase Authentication, Database, and Realtime features. It fills the gap of missing centralized pet healthcare apps in Pakistan. The system functions independently and does not depend on any previous system.
2.2	Product Functions
Major functions include:
• Doctor registration and professional profile management
• Doctor availability scheduling
• Appointment booking with reminders
• Pet registration and profile management
• Community forum posting and interactions
• Offline emergency guide
• Medication reminders with notifications
• AI-based FAQ assistant
2.3	User Classes and Characteristics
1. Pet Owners – Basic mobile users with minimal technical knowledge.
2. Veterinary Doctors – Professional users verifying qualifications.
3. Admin – Oversees system, handles reports, manages content.
Each class has different permission levels and access to features.
2.4	Operating Environment
• Mobile platform: Android 8.0 and above
• Development: Flutter SDK
• Backend: Firebase Authentication, Firestore, Cloud Storage
• Push Notifications: Firebase Cloud Messaging
2.5	Design and Implementation Constraints
These are the limits and rules the developers must follow while building the app.
•	Offline Emergency Guide:
The emergency guide (like first aid tips for pets) must be available even when there’s no internet. This ensures users can get help in urgent situations.
•	Doctors must upload real credentials:
Only verified doctors should be able to use the app to ensure reliability and safety.
•	Only Supabase backend for Phase-1:
Supabase is the only database/server allowed in the first version. This limits the technologies but simplifies development.
•	Internet required for booking, forum, AI assistant:
Some features (like appointments, community forum, AI helper) need online connectivity.
•	Mobile storage limited for images:
The app should handle images efficiently (like compressing photos) so it doesn’t use too much space on the phone.
2.6	User Documentation
This is what helps users understand and use the app:
•	User manual: Step-by-step instructions on how to use the app.
•	In-app tooltips: Short hints appearing in the app to guide users.
•	FAQ section: Common questions and solutions.
•	Video tutorials (future version): Visual guides showing how to use the app.
2.7	Assumptions and Dependencies
These are things the app assumes to be true, or depends on:
•	Stable internet for bookings and forum: If the user’s internet is weak, these features may fail.
•	Doctors comply with real credentials: The system relies on doctors uploading correct information.
•	Firebase services remain available: Firebase downtime will affect the app.
•	AI assistant requires internet: The AI cannot work offline.

3.	External Interface Requirements
How the app interacts with users, devices, software, and networks.
3.1	User Interfaces
•  Flutter UI: Clean, modern, and immersive interface.
•  Immersive Home Dashboard: Full-screen gradient header with dynamic greeting, pet spotlight, and no traditional AppBar for a modern look.
•  Gradient-Themed Headers: Consistent gradient styling across all screen headers for unified branding.
•  Profile Visitor View: Facebook-inspired timeline view for visiting other user profiles, showing only public info (posts, pets) while protecting privacy.
•  Bottom navigation bar: Quick access to main sections – Home, Doctors, Community, Emergency, Profile.
•  Calendar-based appointments: Users can see available times and book easily.
•  Offline emergency guide: Must work even without internet.
•  Forum UI: Similar to social apps, with posts, likes, and comments.
3.2	Hardware Interfaces
Mobile camera: Optional, used for uploading pet or doctor documents.
3.3	Software Interfaces
•  Firebase Authentication: Handles user sign-up/login.
•  Firebase Firestore: Database for storing data.
•  Firebase Cloud Messaging (FCM): Sends notifications to users.
•  Android OS: Platform compatibility.	
•  Flutter backend APIs: Communication between UI and backend services.
3.4	Communications Interfaces
•	HTTPS: Secure communication over the internet.
•	Supabase Cloud Messaging: Push notifications for appointments, reminders, etc.
•	Real-time syncing: Data updates immediately across devices.
4.	System Features
4.1.1	4.2 Pet Registration & Management
4.2.1 Description & Priority
Allows owners to register their pets and manage details.
Priority: High
4.2.2 Stimulus/Response
User adds pet info → System stores details → User can view or edit pet profile.
4.2.3 Functional Requirements
•	REQ-1: System shall allow users to add multiple pets with name, type, breed, and age.
•	REQ-2: Users shall update or remove pet information.
•	REQ-3: System shall store pet photos efficiently to minimize device storage usage.

4.1.2	4.3 Doctor Directory & Appointment Booking
4.3.1 Description & Priority
Displays verified doctors and enables booking appointments.
Priority: High
4.3.2 Stimulus/Response
User selects a doctor → System shows availability → User books appointment → Confirmation sent via notification.
4.3.3 Functional Requirements
•	REQ-1: System shall list only verified doctors.
•	REQ-2: Users shall view doctor profiles including specialization and availability.
•	REQ-3: System shall allow appointment booking with calendar integration.
•	REQ-4: Push notification sent for confirmation, reminders, and cancellations.

4.4 Emergency Guide (Offline)
4.4.1 Description & Priority
Provides first-aid guidance and emergency tips for pets, available offline.
Priority: High
4.4.2 Stimulus/Response
User opens emergency guide System displays step-by-step first-aid instructions.
4.4.3 Functional Requirements
•	REQ-1: Emergency content must be accessible without internet.
•	REQ-2: System shall provide clear instructions with images or videos.
•	REQ-3: System shall allow offline bookmarking of important topics.

4.5 Community Forum
4.5.1 Description & Priority
Allows users to discuss, post questions, and share experiences in a social forum.
Priority: Medium
4.5.2 Stimulus/Response
User posts a question  System displays it Other users can comment, like, and interact.
4.5.3 Functional Requirements
•	REQ-1: Users shall create posts, comments, and likes.
•	REQ-2: System shall award badges for active participation.
•	REQ-3: Admins shall moderate posts to remove inappropriate content.

4.6 Medication Reminders
4.6.1 Description & Priority
Reminds pet owners about medicines, vaccination, and check-ups.
Priority: High
4.6.2 Stimulus/Response
User sets reminder System triggers notification at scheduled time.
4.6.3 Functional Requirements
•	REQ-1: Users shall create, edit, and delete reminders.
•	REQ-2: System shall send push notifications for medication, vaccination, and appointments.
•	REQ-3: Integration with calendar to show upcoming events.
4.7 AI Assistant (Pet Care Tips)
4.7.1 Description & Priority
Provides advice and guidance using AI (requires internet).
Priority: Medium
4.7.2 Stimulus/Response
User asks a question → System sends query to AI → Response displayed in chat.
4.7.3 Functional Requirements
•	REQ-1: System shall analyze user queries and provide advice.
•	REQ-2: Users may view past queries and responses.
•	REQ-3: Admin shall configure AI behavior and responses.
4.8 Admin Dashboard
4.8.1 Description & Priority
Provides control panel for managing doctors, users, forum content, and app analytics.
Priority: High
4.8.2 Stimulus/Response
Admin logs in → Dashboard displays analytics, user reports, and management options.
4.8.3 Functional Requirements
•	REQ-1: Admin shall manage users, doctors, pets, and forum posts.
•	REQ-2: Admin shall approve doctor credentials.
•	REQ-3: Admin shall view analytics like user activity and popular posts.

4.9 Profile & Privacy Management
4.9.1 Description & Priority
Manages how user profiles are displayed to themselves vs. other visitors, ensuring privacy and a professional presentation.
Priority: High
4.9.2 Stimulus/Response
User views a profile → System detects if it’s the current user or a visitor → Displays appropriate view (Edit vs View-Only).
4.9.3 Functional Requirements
•	REQ-1: System shall dynamically display "My Profile" for the owner and the user's name for visitors in the header.
•	REQ-2: Visitors shall NOT see private options like "Edit Profile", "Account Settings", or "Logout".
•	REQ-3: Visitors shall see a "Message" and "Add Friend" button instead of edit controls.
•	REQ-4: Profile shall display a "Timeline" of the user's posts in a social-feed style (similar to Facebook) for both owner and visitors.
•	REQ-5: Users shall be able to navigate to other users' profiles by tapping their name/avatar in community posts or comments.

4.10 Social Interactions
4.10.1 Description & Priority
Enables users to engage with community content through likes, comments, and sharing.
Priority: High
4.10.2 Stimulus/Response
User taps 'Like' → Icon updates instantly (red heart) → Counter increments → Update saved to backend.
User taps 'Comment' → Comments sheet opens → User types & sends → Comment appears in real-time.
4.10.3 Functional Requirements
•	REQ-1: Users shall be able to like and unlike posts.
•	REQ-2: Likes shall be unique per user per post (no duplicate likes).
•	REQ-3: Users shall be able to view all comments on a post.
•	REQ-4: Users shall be able to add new comments.
•	REQ-5: Users shall be able to share posts (via external link copy).





5.	Other Nonfunctional Requirements
5.1	Performance Requirements
Performance requirements define how fast and responsive the app should be.
•	App should load within 3 seconds:
Users expect apps to open quickly. If your app takes too long, people may uninstall it. This ensures the main screens appear fast, giving a smooth experience.
•	Appointment confirmation must process within 1 second:
When a user books an appointment, the system should confirm it almost instantly. Delays could confuse users or cause double bookings.
•	Push notifications delivered instantly (network dependent):
Notifications like appointment reminders, medication alerts, or forum replies should reach the user immediately. This depends on internet speed, but the system should be optimized to send them without delay.
5.2	Safety Requirements
Safety requirements make sure the app protects the user and the pets’ well-being.
•	Emergency guide available offline:
Users must access critical first-aid tips for pets even when there’s no internet, ensuring safety in urgent situations.
•	Incorrect medical info prevented through vet verification:
Only verified doctors can provide advice or content. This prevents fake or harmful guidance from reaching pet owners.
5.3	Security Requirements
Security requirements protect user data and privacy.
•	User data encrypted using Firebase security rules:
All sensitive information (like user login, pet medical records, appointment history) is stored securely and encrypted, so no one can access it without permission.
•	Authentication required for all sensitive actions:
Actions like booking appointments, editing profiles, or viewing pet health info require users to log in, ensuring only authorized people can make changes.
5.4	Software Quality Attributes
• Reliability: 99% uptime
• Usability: Simple interface for pet owners
• Maintainability: Clean Flutter structure
• Scalability: Firebase autoscaling
5.5	Business Rules
These define how the app makes money and enforces policies.
•	Commission on every appointment:
The app takes a percentage from each appointment booked through the platform. This is how the business earns revenue.
•	Only verified doctors listed publicly:
Ensures only trustworthy and qualified professionals appear in the doctor directory, maintaining credibility and user trust.
6.	Other Requirements
•  Multi-language support: App should support English and Urdu to improve usability for all users.
•  Weekly database backups: Ensure all data can be restored in case of loss.
•  Legal compliance: Follow Pakistan’s digital privacy laws to protect user data and build trust.
Appendix A: Glossary
AI – Artificial Intelligence
Vet – Veterinary Doctor
FCM – Firebase Cloud Messaging
Appendix B: Analysis Models
• Use case diagrams
• Class diagrams
• Data flow diagrams
Appendix C: To Be Determined List
TBD-1: Exact AI assistant model
TBD-2: Payment gateway integration