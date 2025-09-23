Here’s a **complete checklist of URLs and requirements** for integrating your API at `https://api.timefactory.io` with Authentik at `https://auth.timefactory.io`, and for connecting to third-party services (GitHub, Coinbase, Schwab):

---

## **1. Authentik (https://auth.timefactory.io) URLs**

**Use these in your API backend OAuth2/OIDC client configuration:**

| Purpose        | URL                                                                          |
| -------------- | ---------------------------------------------------------------------------- |
| Authorization  | `https://auth.timefactory.io/application/o/authorize/`                       |
| Token          | `https://auth.timefactory.io/application/o/token/`                           |
| User Info      | `https://auth.timefactory.io/application/o/userinfo/`                        |
| Token Revoke   | `https://auth.timefactory.io/application/o/revoke/`                          |
| End Session    | `https://auth.timefactory.io/application/o/end-session/`                     |
| JWKS           | `https://auth.timefactory.io/application/o/jwks/`                            |
| OIDC Discovery | `https://auth.timefactory.io/application/o/.well-known/openid-configuration` |

---

## **2. Your API (https://api.timefactory.io) URLs**

**Register these in Authentik’s provider settings:**

| Purpose                       | URL                                                  |
| ----------------------------- | ---------------------------------------------------- |
| Redirect URI                  | `https://api.timefactory.io/auth/callback`           |
| Launch URL                    | `https://api.timefactory.io`                         |
| (Optional) Backchannel Logout | `https://api.timefactory.io/auth/backchannel-logout` |

---

## **3. Third-Party Service URLs and Requirements**

For each service, you must:

### **A. Register your application with the third-party provider:**

-   **GitHub:** https://github.com/settings/developers
-   **Coinbase:** https://developers.coinbase.com/
-   **Schwab:** https://developer.schwabapi.com/

### **B. Provide these to the third-party service:**

-   **Redirect URI:**

    -   `https://api.timefactory.io/oauth/callback/github`
    -   `https://api.timefactory.io/oauth/callback/coinbase`
    -   `https://api.timefactory.io/oauth/callback/schwab`  
        (One for each service, as required.)

-   **Application Name, Description, Logo, etc.** (as required by the provider)

### **C. Obtain from the third-party service:**

-   **Client ID**
-   **Client Secret**
-   **Authorization URL**
-   **Token URL**
-   **API Base URL**
-   **Scopes required for your use case**

---

## **4. Example Third-Party OAuth2 Endpoints**

| Service  | Authorization URL                            | Token URL                                   | API Base URL                 |
| -------- | -------------------------------------------- | ------------------------------------------- | ---------------------------- |
| GitHub   | https://github.com/login/oauth/authorize     | https://github.com/login/oauth/access_token | https://api.github.com/      |
| Coinbase | https://www.coinbase.com/oauth/authorize     | https://api.coinbase.com/oauth/token        | https://api.coinbase.com/v2/ |
| Schwab   | https://api.schwabapi.com/v1/oauth/authorize | https://api.schwabapi.com/v1/oauth/token    | https://api.schwabapi.com/   |

---

## **5. What to Provide and What to Obtain**

| To Authentik (from your API)      | To Your API (from Authentik)              | To Third-Party (from your API)   | To Your API (from Third-Party)      |
| --------------------------------- | ----------------------------------------- | -------------------------------- | ----------------------------------- |
| Redirect URI(s)                   | OIDC endpoints (see section 1)            | Redirect URI(s) for each service | Client ID, Client Secret, Endpoints |
| Launch URL                        | Client ID, Client Secret (from Authentik) | App info (name, logo, etc.)      |                                     |
| (Optional) Backchannel Logout URI |                                           |                                  |                                     |

---

## **Summary**

-   **Configure Authentik** with your API’s redirect and launch URLs.
-   **Configure your API** with Authentik’s OIDC endpoints and credentials.
-   **Register your API** with each third-party service, providing the correct callback URLs.
-   **Store and use** the client credentials and endpoints from each third-party service in your API for OAuth2 flows.

---

**This setup ensures secure SSO via Authentik and seamless integration with third-party APIs.**

# Email + Passkey

This flow provides a modern authentication experience where users can:

-   Sign in with passkeys (if available) - **IMMEDIATE LOGIN ON SUCCESS**
-   Fall back to email verification for new users or recovery
-   Automatically create accounts in the "peers" group
-   Recover access via email if passkey fails

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
