---
name: fhir-android
description: >
  HL7 FHIR and Dutch healthcare standards for Android development. Auto-invoke when building
  Android apps that handle healthcare data, medical records, patient information, FHIR resources,
  zibs (zorginformatiebouwstenen), or when the user mentions FHIR, HL7, Zorgviewer, healthcare,
  zorg, medische gegevens, patiëntdata, WEGIZ, MedMij, LSP, or Dutch healthcare IT terms.
  Covers FHIR R4 resource handling, Dutch healthcare profiles (nictiz), privacy/AVG compliance
  for medical data, and the Android FHIR SDK.
---

# HL7 FHIR & Dutch Healthcare Standards for Android

## Overview

This skill provides guidance for building Android apps that interact with healthcare data following HL7 FHIR standards and Dutch healthcare regulations. It covers the FHIR data model, Dutch profiles (nictiz), privacy requirements, and practical Android implementation patterns.

## FHIR Fundamentals for Android Developers

### What is FHIR?

FHIR (Fast Healthcare Interoperability Resources) is the standard for exchanging healthcare information electronically. Version: **FHIR R4** (4.0.1) is the current stable release used in Dutch healthcare.

### Key FHIR Concepts

| Concept | Description | Android Relevance |
|---------|-------------|-------------------|
| Resource | Basic unit of data (Patient, Observation, etc.) | Maps to data classes/entities |
| Bundle | Collection of resources | API response container |
| Reference | Link between resources | Foreign key equivalent |
| Profile | Constraints on a resource for specific use | Validation rules |
| Extension | Custom data additions | Extra fields on standard resources |
| Coding | Code + system + display | Dropdown/picker values |
| Identifier | Business identifier (BSN, AGB, etc.) | Unique keys for lookup |

### Core FHIR Resources for Dutch Healthcare

| Resource | Dutch Use | Key Fields |
|----------|-----------|------------|
| Patient | Patiëntgegevens | name, birthDate, identifier (BSN), address |
| Practitioner | Zorgverlener | name, identifier (AGB/BIG), qualification |
| Organization | Zorginstelling | name, identifier (URA/AGB), type |
| Observation | Meetwaarden/lab | code, value, effectiveDateTime, status |
| Condition | Diagnoses/problemen | code, clinicalStatus, onsetDateTime |
| MedicationRequest | Medicatievoorschrift | medicationCodeableConcept, dosageInstruction |
| AllergyIntolerance | Allergieën | code, clinicalStatus, type, category |
| Encounter | Contact/bezoek | class, period, serviceProvider |
| DocumentReference | Documenten | type, content, author, date |

## Dutch Healthcare Standards

### Zibs (Zorginformatiebouwstenen)

Zibs are the Dutch clinical building blocks that define how healthcare information is structured. They are **logical information models** — NOT FHIR profiles, but they are mapped to FHIR profiles.

**Key distinction**: 
- **Zib** = logical model (technology-agnostic, defines WHAT data)
- **FHIR Profile** = technical implementation (defines HOW data is structured in FHIR)

Common zibs and their FHIR mappings:

| Zib | FHIR Resource | Profile |
|-----|---------------|---------|
| Patient | Patient | nl-core-Patient |
| Bloeddruk | Observation | nl-core-BloodPressure |
| Lichaamsgewicht | Observation | nl-core-BodyWeight |
| Probleem | Condition | nl-core-Problem |
| AllergieIntolerantie | AllergyIntolerance | nl-core-AllergyIntolerance |
| MedicatieGebruik | MedicationStatement | nl-core-MedicationUse2 |
| Contactpersoon | RelatedPerson | nl-core-ContactPerson |
| Zorgverlener | Practitioner | nl-core-HealthProfessional |
| Zorgaanbieder | Organization | nl-core-HealthcareProvider |

### WEGIZ (Wet Elektronische Gegevensuitwisseling in de Zorg)

The Dutch law mandating electronic health data exchange. Key requirements for Android apps:
- Must support standardized data exchange formats
- Must comply with NEN norms for healthcare IT
- Must enable patient access to their own data
- Must support the national infrastructure for data exchange

### MedMij

The Dutch framework for personal health environments (PGO — Persoonlijke Gezondheidsomgeving):
- Defines information standards for patient-facing apps
- OAuth 2.0 based authentication flow (SMART on FHIR)
- Specific Dutch value sets and coding systems
- Qualification process for PGO apps

### Dutch Coding Systems

| System | OID / URL | Use |
|--------|-----------|-----|
| BSN | 2.16.840.1.113883.2.4.6.3 | Burger Service Nummer (patient ID) |
| AGB | 2.16.840.1.113883.2.4.6.1 | Zorgverlener/instelling code |
| BIG | 2.16.528.1.1007.5.1 | BIG-register (practitioner) |
| UZI | 2.16.528.1.1007.3.1 | UZI-pas (authentication) |
| URA | 2.16.528.1.1007.3.3 | URA-nummer (organization) |
| SNOMED CT | http://snomed.info/sct | Clinical terminology |
| LOINC | http://loinc.org | Lab observations |
| G-Standaard | 2.16.840.1.113883.2.4.4.10 | Medication (Dutch) |

## Android Implementation Patterns

### FHIR SDK Options

**Google Android FHIR SDK** (recommended for Android-native):
- FHIR Engine: local FHIR data store with sync
- Data Capture: structured data entry via FHIR Questionnaire
- Workflow: clinical decision support

**HAPI FHIR** (alternative — Java library):
- Full FHIR parser/serializer
- Works on Android but is heavyweight
- Better for server-side or complex parsing scenarios

### Data Layer Architecture for FHIR

```
presentation/
  └── ViewModel observes domain models

domain/
  ├── model/          → Domain models (NOT FHIR resources)
  │   ├── Patient.kt  → Simplified patient domain model
  │   └── Observation.kt
  ├── repository/     → Interfaces
  └── usecase/        → Business logic (filtering, aggregating)

data/
  ├── fhir/
  │   ├── FhirClient.kt        → Retrofit interface for FHIR server
  │   ├── FhirParser.kt         → FHIR JSON → domain model mapping
  │   └── model/
  │       ├── FhirPatient.kt    → FHIR resource DTOs
  │       └── FhirBundle.kt
  ├── local/
  │   ├── PatientEntity.kt      → Room entity (simplified local cache)
  │   └── PatientDao.kt
  └── repository/
      └── PatientRepositoryImpl.kt  → Combines FHIR API + local cache
```

**Key pattern**: NEVER expose FHIR resource objects to the presentation layer. Always map to domain models. FHIR resources are complex and contain fields irrelevant to the UI.

### FHIR API Integration

```
Base URL pattern: https://fhir-server.example.nl/fhir/R4/

Common endpoints:
GET /Patient?identifier=http://fhir.nl/fhir/NamingSystem/bsn|123456789
GET /Patient/{id}
GET /Observation?patient={patientId}&code=http://loinc.org|85354-9  (blood pressure)
GET /Condition?patient={patientId}&clinical-status=active
GET /MedicationRequest?patient={patientId}&status=active
```

**Search parameters** follow FHIR search spec:
- `?name=Jan` — string search
- `?birthdate=1990-01-01` — date search
- `?_include=Observation:patient` — include referenced resources
- `?_count=20&_offset=0` — pagination
- `?_sort=-date` — sort descending by date

### Authentication: SMART on FHIR

For MedMij-compliant apps:

1. **Discovery**: GET `/.well-known/smart-configuration` from FHIR server
2. **Authorization**: OAuth 2.0 Authorization Code flow with PKCE
3. **Token exchange**: POST to token endpoint with auth code
4. **Access**: Include Bearer token in FHIR API requests
5. **Scopes**: `patient/*.read`, `patient/Observation.read`, etc.

### Handling BSN (Burger Service Nummer)

**Critical privacy requirement**: BSN is classified as a special personal identifier under Dutch law.

Rules for Android apps handling BSN:
- NEVER store BSN in plain text locally — encrypt or don't store
- NEVER log BSN values (not even in debug builds)
- NEVER display full BSN in UI — mask as `***.**.*23` (show last 2 digits max)
- Use BSN only for FHIR server queries, not as local database key
- If caching patient data locally, use the FHIR resource ID, not BSN

### Privacy & Security for Medical Data

Medical data is a **special category** under AVG/GDPR Article 9. Extra requirements:

| Requirement | Implementation |
|-------------|---------------|
| Encryption at rest | Room with SQLCipher, or Android Keystore-backed encryption |
| Encryption in transit | TLS 1.3, certificate pinning on FHIR server |
| Authentication | Biometric + SMART on FHIR tokens |
| Session timeout | Auto-logout after 5 minutes inactivity |
| Audit logging | Log all data access (who, when, what — NOT the data itself) |
| Data minimization | Fetch only the FHIR resources needed for the current view |
| Right to erasure | Ability to delete all local cached data |
| No screenshots | `FLAG_SECURE` on activities showing medical data |
| No backup | `android:allowBackup="false"` for medical data apps |
| Consent | Explicit consent before accessing health data |

### FHIR Data Validation

When receiving FHIR data, validate against Dutch profiles:

1. **Resource type check** — is it the expected resource?
2. **Profile compliance** — does it declare the expected meta.profile?
3. **Required fields** — are mandatory fields present?
4. **Coding validation** — are codes from expected code systems?
5. **Reference integrity** — do references point to existing resources?

### Error Handling for FHIR

FHIR servers return `OperationOutcome` resources for errors:

```
HTTP 400 → OperationOutcome with issue.severity = "error"
HTTP 401 → Token expired, trigger re-authentication
HTTP 403 → Insufficient scope/consent
HTTP 404 → Resource not found (normal for new patients)
HTTP 429 → Rate limited, implement exponential backoff
HTTP 500 → Server error, show user-friendly message, log for support
```

### Useful Resources

- Nictiz FHIR profiles: https://simplifier.net/nictiz
- FHIR R4 spec: https://hl7.org/fhir/R4/
- MedMij: https://www.medmij.nl/
- Zib catalog: https://zibs.nl/
- WEGIZ: https://www.rijksoverheid.nl/onderwerpen/wet-elektronische-gegevensuitwisseling-in-de-zorg-wegiz
- Google Android FHIR SDK: https://github.com/google/android-fhir

## Zorgviewer Context

If the app is part of or interacts with the Zorgviewer ecosystem (regional healthcare information exchange in Northern Netherlands — RIVO-Noord):

- Follow the Zorgviewer Implementation Guide for resource profiles
- Use the regional FHIR endpoints provided by RIVO-Noord
- Validate against the Zorgviewer-specific profiles, NOT against generic nictiz profiles
- The Implementation Guide defines which zibs are in scope and how they map to FHIR
- Validation must check the IG against external standards (zibs, nictiz profiles), NOT against itself
