# Authentik Email + Passkey Authentication Flow Implementation Guide (SIMPLIFIED)

This guide walks you through implementing the Email + Passkey authentication flow directly in the Authentik web interface, with immediate login on passkey success and automatic "peers" group assignment.

## Overview

This flow provides a modern authentication experience where users can:

-   Sign in with passkeys (if available) - **IMMEDIATE LOGIN ON SUCCESS**
-   Fall back to email verification for new users or recovery
-   Automatically create accounts in the "peers" group
-   Recover access via email if passkey fails

## Implementation Steps

### 1. Create Groups

#### Peers Group (for all users)

1. Navigate to **Directory** → **Groups**
2. Click **Create**
3. Configure:
    - **Name**: `peers`
    - **Is superuser**: Unchecked
    - **Parent**: Leave empty

### 2. Create Flows

#### Main Authentication Flow

1. Navigate to **Flows & Stages** → **Flows**
2. Click **Create**
3. Configure:
    - **Name**: `hello universe`
    - **Title**: `Sign in with your email`
    - **Slug**: `hello-universe`
    - **Designation**: `Authentication`
    - **Authentication**: `Require unauthenticated`

#### Passkey Setup Flow

1. Click **Create** again
2. Configure:
    - **Name**: `passkey-setup`
    - **Title**: `Create your passkey`
    - **Slug**: `passkey-setup`
    - **Designation**: `Stage configuration`

### 3. Create Prompts and Stages

#### Email Prompt

1. Navigate to **Flows & Stages** → **Prompts**
2. Click **Create**
3. Configure:
    - **Name**: `email-prompt`
    - **Field Key**: `email`
    - **Label**: `Email Address`
    - **Type**: `Email`
    - **Required**: ✓
    - **Placeholder**: `Enter your email address`
    - **Order**: `0`

#### Email Input Stage

1. Navigate to **Flows & Stages** → **Stages**
2. Click **Create** → **Prompt Stage**
3. Configure:
    - **Name**: `email-stage`
    - **Fields**: Select `email-prompt`

#### User Identification Stage

1. Click **Create** → **Identification Stage**
2. Configure:
    - **Name**: `user-identification`
    - **User fields**: Select `Email`
    - **Sources**: Leave empty
    - **Show matched user**: Unchecked
    - **Show source labels**: Unchecked

#### WebAuthn Authentication Stage

1. Click **Create** → **WebAuthn Authenticator Stage**
2. Configure:
    - **Name**: `passkey-auth-stage`
    - **Configure flow**: Select `passkey-setup`
    - **User verification**: `Preferred`
    - **Authenticator attachment**: `Platform`

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

#### User Update Stage

1. Click **Create** → **User Write Stage**
2. Configure:
    - **Name**: `user-update`
    - **Create users as inactive**: Unchecked
    - **User creation mode**: `Never create`

#### Passkey Setup Configuration Stage

1. Click **Create** → **WebAuthn Authenticator Stage**
2. Configure:
    - **Name**: `passkey-setup-config`
    - **User verification**: `Preferred`
    - **Authenticator attachment**: `Platform`

#### Login Stage

1. Click **Create** → **User Login Stage**
2. Configure:
    - **Name**: `login-stage`

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

#### New User Policy

1. Click **Create** → **Expression Policy**
2. Configure:
    - **Name**: `new-user`
    - **Expression**:
    ```python
    return not bool(request.context.get('pending_user'))
    ```

#### Passkey Available Policy

1. Click **Create** → **Expression Policy**
2. Configure:

    - **Name**: `passkey-available`
    - **Expression**:

    ```python
    # Check if user has WebAuthn session or browser supports conditional UI
    has_webauthn_session = bool(request.session.get('authentik_webauthn_user_handle'))

    # Check if domain has any passkeys and browser supports WebAuthn
    from authentik.stages.authenticator_webauthn.models import WebAuthnDevice
    user_agent = request.META.get('HTTP_USER_AGENT', '')
    webauthn_capable = any(browser in user_agent for browser in ['Chrome', 'Firefox', 'Safari', 'Edge'])
    domain_has_passkeys = WebAuthnDevice.objects.filter(confirmed=True).exists()

    # Try passkey first if conditions are met
    return has_webauthn_session or (webauthn_capable and domain_has_passkeys)
    ```

#### Passkey Failed Policy

1. Click **Create** → **Expression Policy**
2. Configure:
    - **Name**: `passkey-failed`
    - **Expression**:
    ```python
    # Check if passkey auth was attempted but failed
    # This indicates existing user needs recovery
    pending_user = request.context.get('pending_user')
    passkey_failed = request.context.get('passkey_auth_failed', False)
    return bool(pending_user) and passkey_failed
    ```

#### Passkey Success Policy

1. Click **Create** → **Expression Policy**
2. Configure:

    - **Name**: `passkey-success`
    - **Expression**:

    ```python
    # Check if passkey authentication was successful
    # Look for successful WebAuthn authentication in context
    webauthn_user = request.context.get('webauthn_user')
    if webauthn_user:
        return True

    # Also check if current user was authenticated via WebAuthn
    if hasattr(request, 'user') and request.user.is_authenticated:
        # Check if this is a fresh authentication (not from session)
        return request.context.get('webauthn_authenticated', False)

    return False
    ```

### 5. Configure Flow Stage Bindings

#### Main Authentication Flow

Navigate to **Flows & Stages** → **Flows** → Select `hello universe` → **Stage Bindings** tab

**Add the following bindings in the EXACT order below:**

1. **Order 5**: Passkey Auth (Initial - Anonymous)

    - **Stage**: `passkey-auth-stage`
    - **Policy engine mode**: `All`
    - **Invalid response action**: `Continue`
    - **Policies**: `passkey-available`

2. **Order 7**: Login (After Initial Passkey Success)

    - **Stage**: `login-stage`
    - **Policy engine mode**: `All`
    - **Policies**: `passkey-success`
    - **Re-evaluate policies**: ✓

3. **Order 10**: Email Input (Fallback)

    - **Stage**: `email-stage`
    - **No policies** (always shown if previous stages didn't complete)

4. **Order 20**: User Identification

    - **Stage**: `user-identification`

5. **Order 30**: Passkey Auth (Identified Users)

    - **Stage**: `passkey-auth-stage`
    - **Policy engine mode**: `All`
    - **Invalid response action**: `Continue`
    - **Policies**: `user-exists`

6. **Order 32**: Login (After User Passkey Success)

    - **Stage**: `login-stage`
    - **Policy engine mode**: `All`
    - **Policies**: `user-exists`, `passkey-success`
    - **Re-evaluate policies**: ✓

7. **Order 35**: Email Verification (Recovery)

    - **Stage**: `email-verification`
    - **Policy engine mode**: `All`
    - **Policies**: `user-exists`, `passkey-failed`

8. **Order 37**: User Update (Recovery)

    - **Stage**: `user-update`
    - **Policy engine mode**: `All`
    - **Policies**: `user-exists`, `passkey-failed`

9. **Order 38**: Passkey Setup (Recovery)

    - **Stage**: `passkey-setup-config`
    - **Policy engine mode**: `All`
    - **Policies**: `user-exists`, `passkey-failed`

10. **Order 40**: Email Verification (New Users)

    - **Stage**: `email-verification`
    - **Policy engine mode**: `All`
    - **Policies**: `new-user`

11. **Order 50**: User Creation

    - **Stage**: `user-creation`
    - **Policy engine mode**: `All`
    - **Policies**: `new-user`

12. **Order 60**: Passkey Setup (New Users)

    - **Stage**: `passkey-setup-config`
    - **Policy engine mode**: `All`
    - **Policies**: `new-user`

13. **Order 100**: Final Login (New User Path)
    - **Stage**: `login-stage`
    - **Policy engine mode**: `All`
    - **Policies**: `new-user`

#### Passkey Setup Flow

Navigate to the `passkey-setup` flow → **Stage Bindings** tab

Add binding:

1. **Order 10**: Passkey Setup
    - **Stage**: `passkey-setup-config`

### 6. Create Peers Access Policy (Optional)

#### Peers Access Policy

1. Navigate to **Policies** → **Policies**
2. Click **Create** → **Expression Policy**
3. Configure:

    - **Name**: `Peers Access Policy`
    - **Expression**:

    ```python
    # Allow access if user is in peers group
    user = request.user
    if not user or not user.is_authenticated:
        return False

    user_groups = [group.name for group in user.ak_groups.all()]
    return 'peers' in user_groups
    ```

### 7. Configure Application

1. Navigate to **Applications** → **Applications**
2. Select your application or create a new one
3. Set **Authentication flow** to `hello universe`

## Key Features

### **Simplified Flow Logic:**

1. **All users follow the same path** - no admin/non-admin distinctions
2. **Immediate login on passkey success** at two points in the flow
3. **Automatic peers group assignment** for all new users
4. **Email fallback** when passkey isn't available or fails
5. **Recovery flow** for existing users with failed passkeys

### **User Experience Flow:**

#### **Scenario 1: Returning User with Working Passkey**

1. User visits login page
2. Passkey prompt appears (Order 5)
3. User authenticates with passkey
4. **IMMEDIATE LOGIN** (Order 7) - **NO EMAIL PROMPT**

#### **Scenario 2: User with Passkey After Email Entry**

1. User visits login page
2. Passkey not available initially (Order 5 skipped)
3. Email prompt appears (Order 10)
4. User enters email (Order 20 - identification)
5. Passkey prompt for identified user (Order 30)
6. **IMMEDIATE LOGIN** (Order 32) - **NO ADDITIONAL STEPS**

#### **Scenario 3: New User or Recovery**

1. User visits login page
2. Passkey not available (Order 5 skipped)
3. Email prompt appears (Order 10)
4. Continue with email verification and account creation flow
5. New user automatically added to "peers" group

## Benefits

-   **Simplified**: Single flow for all users
-   **Modern UX**: Passkey-first with email fallback
-   **Automatic grouping**: All users in "peers" group
-   **Recovery-friendly**: Email recovery for lost passkeys
-   **Immediate login**: No unnecessary steps after successful passkey auth

## Testing the Flow

1. **Test with existing passkey user**: Should see passkey prompt → immediate login
2. **Test with new user**: Should see email prompt → verification → account creation → passkey setup
3. **Test recovery scenario**: Email prompt → failed passkey → recovery flow

The flow ensures **immediate login** when passkey authentication succeeds, with email prompts only appearing when necessary, and automatically assigns all users to the peers group.
