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
    - **Name**: `hello-universe`
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

#### Identification Stage

1. Click **Create** → **Identification Stage**
2. Configure:
    - **Name**: `identification`
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

#### Peer Creation Stage

1. Click **Create** → **User Write Stage**
2. Configure:
    - **Name**: `peer-creation`
    - **Create users as inactive**: Unchecked
    - **User creation mode**: `Always create`
    - **Create users group**: Select `peers`

#### User Update Stage

1. Click **Create** → **User Write Stage**
2. Configure:
    - **Name**: `peer-update`
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

#### Peer Exists Policy

1. Navigate to **Policies** → **Policies**
2. Click **Create** → **Expression Policy**
3. Configure:
    - **Name**: `peer-exists-policy`
    - **Expression**:
    ```python
    return bool(request.context.get('pending_user'))
    ```

#### New Peer Policy

1. Click **Create** → **Expression Policy**
2. Configure:
    - **Name**: `new-peer-policy`
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

Navigate to **Flows & Stages** → **Flows** → Select `hello-universe` → **Stage Bindings** tab

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

    - **Stage**: `identification`

5. **Order 30**: Passkey Auth (Identified Users)

    - **Stage**: `passkey-auth-stage`
    - **Policy engine mode**: `All`
    - **Invalid response action**: `Continue`
    - **Policies**: `peer-exists`

6. **Order 32**: Login (After User Passkey Success)

    - **Stage**: `login-stage`
    - **Policy engine mode**: `All`
    - **Policies**: `peer-exists`, `passkey-success`
    - **Re-evaluate policies**: ✓

7. **Order 35**: Email Verification (Recovery)

    - **Stage**: `email-verification`
    - **Policy engine mode**: `All`
    - **Policies**: `peer-exists`, `passkey-failed`

8. **Order 37**: User Update (Recovery)

    - **Stage**: `peer-update`
    - **Policy engine mode**: `All`
    - **Policies**: `peer-exists`, `passkey-failed`

9. **Order 38**: Passkey Setup (Recovery)

    - **Stage**: `passkey-setup-config`
    - **Policy engine mode**: `All`
    - **Policies**: `peer-exists`, `passkey-failed`

10. **Order 40**: Email Verification (New Users)

    - **Stage**: `email-verification`
    - **Policy engine mode**: `All`
    - **Policies**: `new-user`

11. **Order 50**: Peer Creation

    - **Stage**: `peer-creation`
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
