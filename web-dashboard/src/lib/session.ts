const TOKEN_KEY = "lolipants_bearer_token";
const USER_KEY = "lolipants_user";

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return sessionStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  sessionStorage.setItem(TOKEN_KEY, token);
}

export function clearSession(): void {
  sessionStorage.removeItem(TOKEN_KEY);
  sessionStorage.removeItem(USER_KEY);
}

export function getCachedUser(): string | null {
  if (typeof window === "undefined") return null;
  return sessionStorage.getItem(USER_KEY);
}

export function setCachedUser(json: string): void {
  sessionStorage.setItem(USER_KEY, json);
}
