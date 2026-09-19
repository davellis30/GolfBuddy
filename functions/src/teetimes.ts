/**
 * Tee-time provider abstraction.
 *
 * Mirrors the iOS `TeeTimeProvider` protocol: the API always searches through
 * a provider, so inventory sources are interchangeable. Today the active
 * provider is a deterministic mock; `LightspeedTeeTimeProvider` is the
 * drop-in for live inventory once the Lightspeed Golf partnership is signed
 * (docs: https://partner-api.docs.chronogolf.com/).
 */

export interface TeeTimeSearchRequest {
  courses: CourseInfo[];
  /** YYYY-MM-DD, course-local date */
  date: string;
  /** HH:MM 24h, course-local */
  earliestTime: string;
  /** HH:MM 24h, course-local */
  latestTime: string;
  players: number;
}

export interface CourseInfo {
  id: string;
  name: string;
  holes: number;
}

export interface TeeTime {
  id: string;
  courseId: string;
  courseName: string;
  /** ISO 8601 with UTC offset */
  date: string;
  availableSlots: number;
  pricePerPlayer: number;
  holes: number;
  isHotDeal: boolean;
}

export interface CourseTeeTimeResult {
  courseId: string;
  courseName: string;
  teeTimes: TeeTime[];
}

export interface TeeTimeProvider {
  readonly name: string;
  searchTeeTimes(request: TeeTimeSearchRequest): Promise<CourseTeeTimeResult[]>;
}

export class ProviderNotConfiguredError extends Error {
  constructor(provider: string, detail: string) {
    super(`${provider} is not configured: ${detail}`);
    this.name = "ProviderNotConfiguredError";
  }
}

// ---------------------------------------------------------------------------
// Deterministic RNG (xorshift32 + FNV-1a seed). Same input -> same output,
// so search results are stable and cacheable per course+date.
// ---------------------------------------------------------------------------

class SeededRng {
  private state: number;

  constructor(seed: number) {
    this.state = seed >>> 0 || 0x9e3779b9;
  }

  private nextUint32(): number {
    let x = this.state;
    x ^= (x << 13) >>> 0;
    x ^= x >>> 17;
    x ^= (x << 5) >>> 0;
    this.state = x >>> 0;
    return this.state;
  }

  nextInt(min: number, max: number): number {
    const range = max - min + 1;
    return min + (this.nextUint32() % range);
  }
}

function hashSeed(str: string): number {
  let h = 0x811c9dc5;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
}

// ---------------------------------------------------------------------------
// Mock provider — realistic-looking availability until a live vendor is wired.
// ---------------------------------------------------------------------------

function toMinutes(hhmm: string): number {
  const [h, m] = hhmm.split(":").map(Number);
  return h * 60 + m;
}

/** UTC offset of America/Chicago for a given course-local wall time. */
function chicagoOffset(hhmmDate: string, minutes: number): string {
  const hh = String(Math.floor(minutes / 60)).padStart(2, "0");
  const mm = String(minutes % 60).padStart(2, "0");
  const probeUtc = Date.parse(`${hhmmDate}T${hh}:${mm}:00Z`);
  const dtf = new Intl.DateTimeFormat("en-US", {
    timeZone: "America/Chicago",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
  const parts = dtf.formatToParts(new Date(probeUtc));
  const get = (t: string): string =>
    parts.find((p) => p.type === t)?.value ?? "00";
  // Normalize "24" hour that some ICU versions emit at midnight.
  const hour = get("hour") === "24" ? "00" : get("hour");
  const wallUtc = Date.parse(
    `${get("year")}-${get("month")}-${get("day")}T${hour}:${get("minute")}:${get("second")}Z`
  );
  const totalMinutes = -Math.round((probeUtc - wallUtc) / 60000);
  const sign = totalMinutes < 0 ? "-" : "+";
  const abs = Math.abs(totalMinutes);
  return `${sign}${String(Math.floor(abs / 60)).padStart(2, "0")}:${String(abs % 60).padStart(2, "0")}`;
}

function priceForHour(hour: number, rng: SeededRng): number {
  if (hour < 8) return rng.nextInt(35, 45);
  if (hour < 11) return rng.nextInt(55, 75);
  if (hour < 14) return rng.nextInt(45, 60);
  if (hour < 16) return rng.nextInt(40, 55);
  return rng.nextInt(25, 35);
}

export class MockTeeTimeProvider implements TeeTimeProvider {
  readonly name = "mock";

  async searchTeeTimes(
    request: TeeTimeSearchRequest
  ): Promise<CourseTeeTimeResult[]> {
    const {courses, date, earliestTime, latestTime, players} = request;

    return courses.map((course) => {
      const rng = new SeededRng(hashSeed(`${course.id}|${date}`));
      const teeTimes: TeeTime[] = [];
      let minutes = toMinutes(earliestTime);
      const endMinutes = toMinutes(latestTime);

      while (minutes < endMinutes) {
        minutes += rng.nextInt(7, 12);
        if (minutes >= endMinutes) break;

        const slots = rng.nextInt(1, 4);
        if (slots < players) continue;
        if (rng.nextInt(0, 4) === 0) continue; // ~20% already booked

        const hour = Math.floor(minutes / 60);
        const basePrice = priceForHour(hour, rng);
        const isHotDeal = rng.nextInt(0, 6) === 0;
        const holes =
          course.holes === 9 ? 9 : rng.nextInt(0, 3) === 0 ? 9 : 18;
        const hh = String(Math.floor(minutes / 60)).padStart(2, "0");
        const mm = String(minutes % 60).padStart(2, "0");

        teeTimes.push({
          id: `${course.id}-${date}-${hh}${mm}`,
          courseId: course.id,
          courseName: course.name,
          date: `${date}T${hh}:${mm}:00${chicagoOffset(date, minutes)}`,
          availableSlots: slots,
          pricePerPlayer: isHotDeal
            ? Math.round(basePrice * 0.75 * 100) / 100
            : basePrice,
          holes,
          isHotDeal,
        });
      }

      teeTimes.sort((a, b) => (a.date < b.date ? -1 : 1));
      return {courseId: course.id, courseName: course.name, teeTimes};
    });
  }
}

// ---------------------------------------------------------------------------
// Lightspeed Golf Partner API v2 adapter (live inventory).
// Wired up automatically when LIGHTSPEED_CLIENT_ID / LIGHTSPEED_CLIENT_SECRET
// are set in the Functions runtime config. Until then it refuses to run so
// callers can never mistake mock data for bookable inventory.
// ---------------------------------------------------------------------------

export interface LightspeedConfig {
  clientId: string;
  clientSecret: string;
  /** Defaults to the production Partner API base. */
  baseUrl?: string;
}

export class LightspeedTeeTimeProvider implements TeeTimeProvider {
  readonly name = "lightspeed";
  private readonly baseUrl: string;

  constructor(private readonly config: LightspeedConfig) {
    this.baseUrl =
      config.baseUrl ?? "https://api.chronogolf.com/partner_api/v2";
  }

  async searchTeeTimes(): Promise<CourseTeeTimeResult[]> {
    // Next step after the partnership agreement is signed:
    //  1. OAuth2 client-credentials exchange -> access token (2h TTL, refresh).
    //  2. Map CalendarCaddy course ids -> Lightspeed organization ids.
    //  3. GET {base}/organizations/:id/teetimes -> normalize into TeeTime[].
    //  4. POST {base}/organizations/:id/reservation_requests (hold) and
    //     POST {base}/organizations/:id/reservations (book) for booking.
    // Rate limit: 200 req/min.
    void this.config;
    void this.baseUrl;
    throw new ProviderNotConfiguredError(
      "Lightspeed",
      "live booking flow not implemented yet — partnership pending"
    );
  }
}

/** Picks the live provider when credentials exist, otherwise the mock. */
export function teeTimeProvider(): TeeTimeProvider {
  const clientId = process.env.LIGHTSPEED_CLIENT_ID;
  const clientSecret = process.env.LIGHTSPEED_CLIENT_SECRET;
  if (clientId && clientSecret) {
    return new LightspeedTeeTimeProvider({clientId, clientSecret});
  }
  return new MockTeeTimeProvider();
}
