# ~Frictionless Authentik Flow

This guide implements Email + Passkey authentication using three distinct, specialized flows for maximum clarity and maintainability.

## Flow Architecture

```mermaid
    A[User arrives] --> B[Authentication Flow]
    B -->|Success| C[Login Complete]
    B -->|No account| D[Enrollment Flow]
    B -->|Lost passkey| E[Recovery Flow]
    D --> F[Account Created + Passkey Setup]
    E --> G[Access Restored + New Passkey]
    F --> C
    G --> C
```

## Overview

This approach uses three specialized flows:

-   **Authentication Flow**: Passkey-first login for existing users
-   **Enrollment Flow**: New user registration with email verification
-   **Recovery Flow**: Account recovery when passkey is lost

## Prerequisites

Before starting, ensure:

1. **Authentik is running** and accessible via HTTPS
2. **Email is configured** in **System** → **Settings** → **Email**
3. **Domain is set** in **System** → **Settings** → **General**
4. You have **admin access** to Authentik web interface

### 1. Create Groups

#### Peers Group (for all users)

1. Navigate to **Directory** → **Groups**
2. Click **Create**
3. Configure:
    - **Name**: `peers`
    - **Is superuser**: Unchecked
    - **Parent**: Leave empty

### 2. Create Flows

#### Authentication Flow (Primary)

1. Navigate to **Flows & Stages** → **Flows**
2. Click **Create**
3. Configure:
    - **Name**: `auth-flow`
    - **Title**: `Sign in`
    - **Slug**: `auth-flow`
    - **Designation**: `Authentication`
    - **Authentication**: `Require no authentication`
    - **Denied action**: `MESSAGE_CONTINUE`

#### Enrollment Flow

1. Click **Create**
2. Configure:
    - **Name**: `enrollment-flow`
    - **Title**: `Create Account`
    - **Slug**: `enrollment-flow`
    - **Designation**: `Enrollment`
    - **Authentication**: `Require no authentication`
    - **Denied action**: `MESSAGE`

#### Recovery Flow

1. Click **Create**
2. Configure:
    - **Name**: `recovery-flow`
    - **Title**: `Recover Access`
    - **Slug**: `recovery-flow`
    - **Designation**: `Recovery`
    - **Authentication**: `Require no authentication`
    - **Denied action**: `MESSAGE`

### 3. Create Stages

#### WebAuthn Authentication Stage

1. Navigate to **Flows & Stages** → **Stages**
2. Click **Create** → **Authenticator Validation Stage**
3. Configure:
    - **Name**: `webauthn-auth`
    - **Device classes**: Select `WebAuthn Authenticators`
    - **Not configured action**: `Continue`
    - **Last validation threshold**: `0 seconds`

#### WebAuthn Setup Stage

1. Click **Create** → **WebAuthn Authenticator Setup Stage**
2. Configure:
    - **Name**: `webauthn-setup`
    - **Authenticator type name**: `Passkey`
    - **Configure flow**: Leave empty
    - **User verification**: `Preferred`
    - **Resident key requirement**: `Preferred`

#### Email Identification Stage

1. Click **Create** → **Identification Stage**
2. Configure:
    - **Name**: `email-identification`
    - **User fields**: Select `Email`
    - **Sources**: Leave empty
    - **Show matched user**: Unchecked
    - **Show source labels**: Unchecked
    - **Enrollment flow**: Select `enrollment-flow`
    - **Recovery flow**: Select `recovery-flow`

#### Email Verification Stage

1. Click **Create** → **Email Stage**
2. Configure:
    - **Name**: `email-verification`
    - **Use global settings**: ✓
    - **Activate user on success**: ✓

#### User Creation Stage

1. Click **Create** → **User Write Stage**
2. Configure:
    - **Name**: `user-creation`
    - **Create users as inactive**: Unchecked
    - **User creation mode**: `Always create`
    - **Create users group**: Select `peers`

#### User Recovery Stage

1. Click **Create** → **User Write Stage**
2. Configure:
    - **Name**: `user-recovery`
    - **Create users as inactive**: Unchecked
    - **User creation mode**: `Never create`

#### Login Stage

1. Click **Create** → **User Login Stage**
2. Configure:
    - **Name**: `login`

### 4. Create Policies

#### User Exists Policy

1. Navigate to **Policies** → **Policies**
2. Click **Create** → **Expression Policy**
3. Configure:
    - **Name**: `user-exists`
    - **Expression**:
    ```python
    return bool(request.context.get('pending_user'))
    ```

#### Authentication Success Policy

1. Click **Create** → **Expression Policy**
2. Configure:
    - **Name**: `auth-success`
    - **Expression**:
    ```python
    return bool(request.user and request.user.is_authenticated)
    ```

### 5. Configure Flow Stage Bindings

#### Authentication Flow (Primary)

Navigate to **Flows & Stages** → **Flows** → Select `auth-flow` → **Stage Bindings** tab

1. **Order 10**: WebAuthn Authentication

    - **Stage**: `webauthn-auth`
    - **Evaluate when stage is run**: ✓
    - **Invalid response behavior**: `RETRY`
    - **Policy engine mode**: `any`

2. **Order 20**: Login (After WebAuthn Success)

    - **Stage**: `login`
    - **Evaluate when stage is run**: ✓
    - **Invalid response behavior**: `RETRY`
    - **Policy engine mode**: `all`
    - **Add Policy Binding**:
        - **Policy**: `auth-success`
        - **Enabled**: ✓
        - **Negate result**: Unchecked
        - **Order**: `0`
        - **Timeout**: `30`
        - **Failure result**: `Don't pass`

#### Enrollment Flow

Navigate to **Flows & Stages** → **Flows** → Select `enrollment-flow` → **Stage Bindings** tab

1. **Order 10**: Email Verification

    - **Stage**: `email-verification`
    - **Evaluate when flow is planned**: ✓
    - **Invalid response behavior**: `RETRY`
    - **Policy engine mode**: `any`

2. **Order 20**: User Creation

    - **Stage**: `user-creation`
    - **Evaluate when flow is planned**: ✓
    - **Invalid response behavior**: `RESTART`
    - **Policy engine mode**: `any`

3. **Order 30**: WebAuthn Setup

    - **Stage**: `webauthn-setup`
    - **Evaluate when flow is planned**: ✓
    - **Invalid response behavior**: `RETRY`
    - **Policy engine mode**: `any`

4. **Order 40**: Login
    - **Stage**: `login`
    - **Evaluate when flow is planned**: ✓
    - **Invalid response behavior**: `RESTART`
    - **Policy engine mode**: `any`

#### Recovery Flow

Navigate to **Flows & Stages** → **Flows** → Select `recovery-flow` → **Stage Bindings** tab

1. **Order 10**: Email Verification

    - **Stage**: `email-verification`
    - **Evaluate when flow is planned**: ✓
    - **Invalid response behavior**: `RETRY`
    - **Policy engine mode**: `any`

2. **Order 20**: User Recovery

    - **Stage**: `user-recovery`
    - **Evaluate when flow is planned**: ✓
    - **Invalid response behavior**: `RESTART`
    - **Policy engine mode**: `any`

3. **Order 30**: WebAuthn Setup

    - **Stage**: `webauthn-setup`
    - **Evaluate when flow is planned**: ✓
    - **Invalid response behavior**: `RETRY`
    - **Policy engine mode**: `any`

4. **Order 40**: Login
    - **Stage**: `login`
    - **Evaluate when flow is planned**: ✓
    - **Invalid response behavior**: `RESTART`
    - **Policy engine mode**: `any`

### 6. Configure Application

1. Navigate to **Applications** → **Applications**
2. Select your application or create a new one
3. Set **Authentication flow** to `auth-flow`

## Validate Configuration

After setup, verify your configuration:

### Check Groups

1. Navigate to **Directory** → **Groups**
2. Confirm `peers` group exists

### Check Flows

1. Navigate to **Flows & Stages** → **Flows**
2. Verify all 3 flows are created:
    - `auth-flow` (Designation: Authentication)
    - `enrollment-flow` (Designation: Enrollment)
    - `recovery-flow` (Designation: Recovery)

### Check Stages

1. Navigate to **Flows & Stages** → **Stages**
2. Verify all 7 stages are created:
    - `webauthn-auth` (Authenticator Validation Stage)
    - `webauthn-setup` (WebAuthn Authenticator Setup Stage)
    - `email-identification` (Identification Stage)
    - `email-verification` (Email Stage)
    - `user-creation` (User Write Stage)
    - `user-recovery` (User Write Stage)
    - `login` (User Login Stage)

### Check Policies

1. Navigate to **Policies** → **Policies**
2. Verify 2 policies exist:
    - `user-exists`
    - `auth-success`

### Check Flow Bindings

1. Navigate to **Flows & Stages** → **Flows** → `auth-flow`
2. Click **Stage Bindings** tab
3. Verify 5 bindings in correct order (10, 20, 30, 40, 50)

## Key Stage Updates Made

### **WebAuthn Authentication Stage**

-   **Changed to**: `Authenticator Validation Stage`
-   **Device classes**: `WebAuthn Authenticators`
-   **Not configured action**: `Continue` (allows flow to proceed if no WebAuthn configured)

### **WebAuthn Setup Stage**

-   **Correct type**: `WebAuthn Authenticator Setup Stage`
-   **Purpose**: Enrolls new WebAuthn authenticators

### **Stage Binding Settings**

-   **Removed**: `Invalid response action` (not applicable to Authenticator Validation Stage)
-   **Updated**: Policy evaluation settings to use `Re-evaluate policies` checkbox

## User Experience

### **Scenario 1: Returning User**

1. **Authentication Flow** → WebAuthn prompt → **Immediate login**

### **Scenario 2: New User**

1. **Authentication Flow** → WebAuthn fails/skipped → Email identification
2. Email not found → **Redirected to Enrollment Flow**
3. Email verification → Account creation → Passkey setup → Login

### **Scenario 3: Lost Passkey**

1. **Authentication Flow** → WebAuthn fails/skipped → Email identification
2. Click "Recover Access" → **Redirected to Recovery Flow**
3. Email verification → New passkey setup → Login

## Security Considerations

### WebAuthn Settings

-   **User verification: Preferred** - Requires biometric/PIN when available
-   **Authenticator attachment: Platform** - Uses device-built authenticators (Touch ID, Windows Hello, etc.)

### Email Security

-   Use **HTTPS only** for email verification links
-   Email verification links expire automatically
-   Users must verify email before account activation

### Group Permissions

-   All users automatically join `peers` group
-   Review and configure `peers` group permissions as needed
-   Consider additional authorization policies per application

## Component Summary

### **Total Components:**

-   **1 Group** (`peers`)
-   **3 Flows** (`auth-flow`, `enrollment-flow`, `recovery-flow`)
-   **7 Stages** (2 WebAuthn + 5 supporting stages)
-   **2 Policies** (`user-exists`, `auth-success`)
-   **12 Stage Bindings** (5 + 4 + 3)

## Testing Each Flow (Detailed)

### **Test Authentication Flow**

1. Open incognito/private browser window
2. Navigate to your application
3. **For existing user with passkey:**
    - WebAuthn prompt appears immediately
    - Use fingerprint/Face ID/security key
    - **Immediate login** (no email prompt)
4. **For existing user without passkey:**
    - WebAuthn prompt (click Cancel/Skip)
    - Email input field appears
    - Enter existing email address
    - WebAuthn prompt appears again
    - Use fingerprint/Face ID or cancel to proceed
    - Login successful

### **Test Enrollment Flow**

1. Use different browser/device
2. Navigate to application
3. **Expected flow:**
    - WebAuthn prompt (click Cancel/Skip)
    - Email input with new email address
    - "Create Account" button appears
    - Click "Create Account" → Redirected to Enrollment Flow
    - Check email for verification link
    - Click verification link
    - Account created automatically
    - WebAuthn setup prompt
    - Setup complete → Login successful

### **Test Recovery Flow**

1. Use different browser/device
2. Navigate to application
3. **Expected flow:**
    - WebAuthn prompt (click Cancel/Skip)
    - Email input with existing email
    - "Recover Access" button appears
    - Click "Recover Access" → Redirected to Recovery Flow
    - Check email for verification link
    - Click verification link
    - WebAuthn setup for new device
    - Setup complete → Login successful
