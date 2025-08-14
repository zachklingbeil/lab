# Authentik Email + Passkey Authentication Flow Implementation Guide (SIMPLIFIED)

This guide walks you through implementing the Email + Passkey authentication flow directly in the Authentik web interface, with immediate login on passkey success and automatic "peers" group assignment.

## Overview

This flow provides a modern authentication experience where users can:

-   Sign in with passkeys (if available) - **IMMEDIATE LOGIN ON SUCCESS**
-   Fall back to email verification for new users or recovery
-   Automatically create accounts in the "peers" group
-   Recover access via email if passkey fails

### 6. Configure Application

1. Navigate to **Applications** → **Applications**
2. Select your application or create a new one
3. Set **Authentication flow** to `hello-universe`

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
