// Mockup dataset for the `dev-seed-mockups` Edge Function.
//
// This file is deliberately a static, hand-curated dataset rather than a
// generator. The goal is realistic-looking SoHo accounts (4 personal +
// 6 business covering goods / service / events) that we can wipe and
// re-seed with one button.
//
// Photo URLs use Unsplash's stable photo-id CDN paths — they don't need
// any auth and stay live indefinitely. If a photo ever 404s, swap it for
// any other unsplash.com image; the seed is forgiving.
//
// Identity convention:
//   * All mockup auth users have email `<handle>@mockup.beepbip`.
//   * That email pattern is the ONLY signal the cleanup pass uses to
//     decide whether to delete a user. Don't reuse this domain elsewhere.

export const MOCKUP_EMAIL_DOMAIN = "mockup.beepbip";
export const MOCKUP_PASSWORD = "mockup-pa55w0rd!"; // dev-only; never deployed

export type MockPersonal = {
  handle: string; // becomes <handle>@mockup.beepbip
  name: string;
  bio: string;
  photo_url: string;
  interests: string[]; // must be slugs from public.interests
  social_handles: Record<string, string>;
  date_of_birth: string;
  gender: string;
  // Optional location & post for richer feed.
  location?: { lat: number; lng: number; address: string };
  posts?: Array<{ content: string; images: string[]; hashtags: string[] }>;
};

export type MockBusiness = {
  handle: string;
  business_name: string;
  category: string;
  description: string;
  logo_url: string;
  cover_url: string;
  services: string[];
  hashtags: string[]; // max 5
  social_handles: Record<string, string>;
  website: string;
  phone: string;
  hours: Array<{
    day_of_week: number; // 0 = Sunday
    open_time: string | null; // "HH:MM" or null when closed
    close_time: string | null;
    is_closed: boolean;
  }>;
  location: { lat: number; lng: number; address: string };
  listings: Array<{
    type: "service" | "item" | "event";
    title: string;
    description: string;
    price_cents: number;
    images: string[];
    hashtags: string[];
    duration_minutes?: number; // services
    capacity?: number; // events
    stock?: number; // items
    starts_at?: string; // events (ISO)
    ends_at?: string; // events (ISO)
  }>;
  posts?: Array<{ content: string; images: string[]; hashtags: string[] }>;
};

// Standard SoHo business hours block reused across most businesses.
const HOURS_STANDARD: MockBusiness["hours"] = [
  { day_of_week: 0, open_time: "10:00", close_time: "17:00", is_closed: false },
  { day_of_week: 1, open_time: "08:00", close_time: "19:00", is_closed: false },
  { day_of_week: 2, open_time: "08:00", close_time: "19:00", is_closed: false },
  { day_of_week: 3, open_time: "08:00", close_time: "19:00", is_closed: false },
  { day_of_week: 4, open_time: "08:00", close_time: "20:00", is_closed: false },
  { day_of_week: 5, open_time: "08:00", close_time: "21:00", is_closed: false },
  { day_of_week: 6, open_time: "09:00", close_time: "20:00", is_closed: false },
];

const HOURS_EVENINGS: MockBusiness["hours"] = [
  { day_of_week: 0, open_time: null, close_time: null, is_closed: true },
  { day_of_week: 1, open_time: null, close_time: null, is_closed: true },
  { day_of_week: 2, open_time: "17:00", close_time: "23:00", is_closed: false },
  { day_of_week: 3, open_time: "17:00", close_time: "23:00", is_closed: false },
  { day_of_week: 4, open_time: "17:00", close_time: "00:00", is_closed: false },
  { day_of_week: 5, open_time: "17:00", close_time: "01:00", is_closed: false },
  { day_of_week: 6, open_time: "16:00", close_time: "01:00", is_closed: false },
];

// Future-dated event timestamps so events don't appear "ended" in feeds.
function inDays(days: number, atHour = 19): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  d.setHours(atHour, 0, 0, 0);
  return d.toISOString();
}

function plusHours(iso: string, hours: number): string {
  const d = new Date(iso);
  d.setHours(d.getHours() + hours);
  return d.toISOString();
}

// ---------------------------------------------------------------------------
// Personal accounts
// ---------------------------------------------------------------------------

export const MOCK_PERSONAL: MockPersonal[] = [
  {
    handle: "alex.morgan",
    name: "Alex Morgan",
    bio:
      "Street photographer chasing window light in SoHo. Coffee snob, bookstore loiterer, occasionally DJs.",
    photo_url:
      "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&q=80",
    interests: ["art", "coffee", "music", "fashion"],
    social_handles: { instagram: "alexmorgan.shoots", website: "alexmorgan.co" },
    date_of_birth: "1997-04-12",
    gender: "female",
    location: {
      lat: 40.7239,
      lng: -74.0007,
      address: "Greene St & Spring St, SoHo",
    },
    posts: [
      {
        content:
          "Looking for a darkroom co-op in SoHo or LES — anyone know a good spot for B&W film?",
        images: [
          "https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=900&q=80",
        ],
        hashtags: ["photography", "soho", "filmphotography"],
      },
    ],
  },
  {
    handle: "mia.chen",
    name: "Mia Chen",
    bio:
      "Vinyl collector. Crate-digger. House & jazz. Always trading, always listening — say hi if you see me at Revolver.",
    photo_url:
      "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600&q=80",
    interests: ["music", "nightlife", "fashion"],
    social_handles: { instagram: "mia.spins", tiktok: "miaspins" },
    date_of_birth: "1995-11-03",
    gender: "female",
    location: {
      lat: 40.7245,
      lng: -73.9970,
      address: "Prince St & Mercer St, SoHo",
    },
    posts: [
      {
        content:
          "Hosting a vinyl swap at my place this weekend — bring 5 records, leave with 5. DM if you want in.",
        images: [
          "https://images.unsplash.com/photo-1461360228754-6e81c478b882?w=900&q=80",
        ],
        hashtags: ["vinyl", "musiccommunity", "soho"],
      },
    ],
  },
  {
    handle: "jordan.lee",
    name: "Jordan Lee",
    bio:
      "Home baker on a sourdough quest. Trying every croissant in Manhattan, slowly. Also runs.",
    photo_url:
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600&q=80",
    interests: ["food", "fitness", "coffee"],
    social_handles: { instagram: "jordans.bakes" },
    date_of_birth: "1992-06-21",
    gender: "male",
    location: {
      lat: 40.7218,
      lng: -74.0024,
      address: "Broome St & Wooster St, SoHo",
    },
  },
  {
    handle: "sam.rivera",
    name: "Sam Rivera",
    bio:
      "Freelance brand designer. Type, posters, indie zines. Open to collabs with small SoHo brands.",
    photo_url:
      "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=600&q=80",
    interests: ["art", "tech", "fashion", "business"],
    social_handles: { instagram: "samrivera.design", website: "samrivera.studio" },
    date_of_birth: "1994-02-18",
    gender: "non-binary",
    location: {
      lat: 40.7224,
      lng: -73.9959,
      address: "Spring St & Lafayette St, SoHo",
    },
    posts: [
      {
        content:
          "Free 30-min logo critique for any SoHo small biz this week — DM me a link.",
        images: [],
        hashtags: ["design", "smallbiz", "soho"],
      },
    ],
  },
];

// ---------------------------------------------------------------------------
// Business accounts — 2 goods, 2 service, 2 events
// ---------------------------------------------------------------------------

export const MOCK_BUSINESSES: MockBusiness[] = [
  // ============================== GOODS (item) ==============================
  {
    handle: "sweetcrumb",
    business_name: "Sweet Crumb Bakery",
    category: "Bakery",
    description:
      "Slow-fermented sourdough, hand-laminated croissants, and seasonal galettes. Baked overnight in our SoHo basement, on the shelf by 7am. Family-run since 2019.",
    logo_url:
      "https://images.unsplash.com/photo-1517686469429-8bdb88b9f907?w=400&q=80",
    cover_url:
      "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=1400&q=80",
    services: ["Sourdough", "Pastries", "Custom orders", "Wholesale"],
    hashtags: ["bakery", "sourdough", "soho", "smallbatch", "pastries"],
    social_handles: {
      instagram: "sweetcrumb.nyc",
      tiktok: "sweetcrumb",
    },
    website: "https://sweetcrumb.example",
    phone: "+1-212-555-0142",
    hours: HOURS_STANDARD,
    location: {
      lat: 40.7232,
      lng: -74.0009,
      address: "92 Spring St, New York, NY 10012",
    },
    listings: [
      {
        type: "item",
        title: "Country Sourdough Loaf",
        description:
          "32-hour cold-fermented loaf with a deep crust and open crumb. King Arthur bread flour blended with our house levain.",
        price_cents: 1200,
        images: [
          "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=1200&q=80",
          "https://images.unsplash.com/photo-1586444248902-2f64eddc13df?w=1200&q=80",
        ],
        hashtags: ["sourdough", "bread", "soho"],
        stock: 24,
      },
      {
        type: "item",
        title: "Butter Croissant — Box of 4",
        description:
          "All-butter, three-day laminated dough. Best within 24 hours of pickup. Limit two boxes per order.",
        price_cents: 1800,
        images: [
          "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=1200&q=80",
        ],
        hashtags: ["croissant", "pastry", "breakfast"],
        stock: 18,
      },
      {
        type: "item",
        title: "Seasonal Plum Galette",
        description:
          "Free-form rustic tart with Hudson Valley plums and almond cream. Available through stone-fruit season.",
        price_cents: 2200,
        images: [
          "https://images.unsplash.com/photo-1464195244916-405fa0a82545?w=1200&q=80",
        ],
        hashtags: ["galette", "seasonal", "dessert"],
        stock: 6,
      },
    ],
    posts: [
      {
        content:
          "First batch of plum galettes is out at 9am tomorrow — only 6, first come first served.",
        images: [
          "https://images.unsplash.com/photo-1464195244916-405fa0a82545?w=900&q=80",
        ],
        hashtags: ["galette", "soho"],
      },
    ],
  },
  {
    handle: "revolverecords",
    business_name: "Revolver Records",
    category: "Record Store",
    description:
      "Independent record shop on Crosby. New & used vinyl across jazz, soul, hip-hop, and global grooves. Trade-ins welcome — bring a stack, leave with credit.",
    logo_url:
      "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&q=80",
    cover_url:
      "https://images.unsplash.com/photo-1515847049296-a281d6401047?w=1400&q=80",
    services: ["New vinyl", "Used vinyl", "Trade-ins", "Listening bar"],
    hashtags: ["vinyl", "records", "music", "soho", "jazz"],
    social_handles: {
      instagram: "revolver.soho",
    },
    website: "https://revolversoho.example",
    phone: "+1-212-555-0177",
    hours: HOURS_STANDARD,
    location: {
      lat: 40.7195,
      lng: -73.9988,
      address: "44 Crosby St, New York, NY 10012",
    },
    listings: [
      {
        type: "item",
        title: "A Love Supreme — John Coltrane (Reissue)",
        description:
          "180g audiophile reissue, gatefold sleeve, mono master. New, sealed.",
        price_cents: 3500,
        images: [
          "https://images.unsplash.com/photo-1461360228754-6e81c478b882?w=1200&q=80",
        ],
        hashtags: ["jazz", "vinyl", "coltrane"],
        stock: 5,
      },
      {
        type: "item",
        title: "Pro-Ject T1 Phono Turntable",
        description:
          "Belt-driven, factory-aligned cartridge, built-in phono pre-amp. Demo unit on the floor.",
        price_cents: 39900,
        images: [
          "https://images.unsplash.com/photo-1487180144351-b8472da7d491?w=1200&q=80",
        ],
        hashtags: ["turntable", "hifi"],
        stock: 2,
      },
      {
        type: "item",
        title: "Mystery Crate — 5 used LPs ($25)",
        description:
          "Dealer's choice — 5 randomly picked records from this week's haul. All G+ or better, no skips.",
        price_cents: 2500,
        images: [
          "https://images.unsplash.com/photo-1471478331149-c72f17e33c73?w=1200&q=80",
        ],
        hashtags: ["mystery", "vinyl", "deal"],
        stock: 12,
      },
    ],
    posts: [
      {
        content:
          "Just took in 200+ records from a Brooklyn estate — soul, jazz, and Brazilian gold. Pulled tomorrow.",
        images: [
          "https://images.unsplash.com/photo-1471478331149-c72f17e33c73?w=900&q=80",
        ],
        hashtags: ["records", "newarrivals"],
      },
    ],
  },

  // =============================== SERVICE ==================================
  {
    handle: "claystudio",
    business_name: "Crosby Clay Studio",
    category: "Pottery Studio",
    description:
      "A small, light-filled ceramics studio on Crosby. Beginner classes, open studio for members, and one-off date nights. Six wheels, two kilns, no big egos.",
    logo_url:
      "https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=400&q=80",
    cover_url:
      "https://images.unsplash.com/photo-1493106819501-66d381c466f1?w=1400&q=80",
    services: ["Beginner classes", "Date nights", "Open studio", "Private events"],
    hashtags: ["pottery", "ceramics", "soho", "class", "datenight"],
    social_handles: {
      instagram: "crosbyclay",
    },
    website: "https://crosbyclay.example",
    phone: "+1-212-555-0188",
    hours: [
      { day_of_week: 0, open_time: "10:00", close_time: "18:00", is_closed: false },
      { day_of_week: 1, open_time: null, close_time: null, is_closed: true },
      { day_of_week: 2, open_time: "11:00", close_time: "21:00", is_closed: false },
      { day_of_week: 3, open_time: "11:00", close_time: "21:00", is_closed: false },
      { day_of_week: 4, open_time: "11:00", close_time: "21:00", is_closed: false },
      { day_of_week: 5, open_time: "11:00", close_time: "22:00", is_closed: false },
      { day_of_week: 6, open_time: "10:00", close_time: "20:00", is_closed: false },
    ],
    location: {
      lat: 40.7202,
      lng: -73.9991,
      address: "61 Crosby St, New York, NY 10012",
    },
    listings: [
      {
        type: "service",
        title: "Intro to the Wheel — 2hr Class",
        description:
          "Hands-on intro for absolute beginners. Make one mug + one bowl. Glazing and firing included; pickup in two weeks.",
        price_cents: 9500,
        images: [
          "https://images.unsplash.com/photo-1493106819501-66d381c466f1?w=1200&q=80",
        ],
        hashtags: ["class", "beginner", "pottery"],
        duration_minutes: 120,
      },
      {
        type: "service",
        title: "Date Night Pottery (for two)",
        description:
          "Two seats, one wheel, one instructor. Wine welcome (we'll provide cups — clay ones, naturally).",
        price_cents: 18500,
        images: [
          "https://images.unsplash.com/photo-1610701596061-2ecf227e85b2?w=1200&q=80",
        ],
        hashtags: ["datenight", "pottery", "couples"],
        duration_minutes: 150,
      },
      {
        type: "service",
        title: "Open Studio Membership (Monthly)",
        description:
          "Unlimited studio access, 25 lb clay/month, kiln firings included. Members can book a wheel up to a week ahead.",
        price_cents: 22000,
        images: [
          "https://images.unsplash.com/photo-1525909002-1b05e0c869d8?w=1200&q=80",
        ],
        hashtags: ["membership", "studio"],
        duration_minutes: 60,
      },
    ],
    posts: [
      {
        content:
          "Two seats opened up for Saturday's Intro to the Wheel class — DM to grab them.",
        images: [],
        hashtags: ["class", "soho"],
      },
    ],
  },
  {
    handle: "pawpalace",
    business_name: "Paw Palace",
    category: "Pet Services",
    description:
      "Full-service grooming and dog walking on Wooster. Fear-free certified groomers, small-batch shampoo bar, and a quiet back room for anxious pups.",
    logo_url:
      "https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=400&q=80",
    cover_url:
      "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=1400&q=80",
    services: ["Grooming", "Dog walking", "Bath & brush", "Nail trims"],
    hashtags: ["pets", "grooming", "soho", "dogs"],
    social_handles: {
      instagram: "pawpalace.soho",
    },
    website: "https://pawpalace.example",
    phone: "+1-212-555-0123",
    hours: HOURS_STANDARD,
    location: {
      lat: 40.7227,
      lng: -74.0021,
      address: "118 Wooster St, New York, NY 10012",
    },
    listings: [
      {
        type: "service",
        title: "Full Groom — Small Dog (under 25 lb)",
        description:
          "Bath, blow-dry, breed-appropriate cut, ear & nail care. Includes a complimentary bandana.",
        price_cents: 8500,
        images: [
          "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=1200&q=80",
        ],
        hashtags: ["grooming", "dogs"],
        duration_minutes: 90,
      },
      {
        type: "service",
        title: "30-min SoHo Walk",
        description:
          "Solo or pair walk through the SoHo loop with photo updates. Insured & bonded walkers, leash-and-harness check at every pickup.",
        price_cents: 3200,
        images: [
          "https://images.unsplash.com/photo-1601758125946-6ec2ef64daf8?w=1200&q=80",
        ],
        hashtags: ["dogwalking", "soho"],
        duration_minutes: 30,
      },
      {
        type: "service",
        title: "Nail Trim Walk-in",
        description:
          "Quick nail trim, no appointment needed. We dremel finish on request.",
        price_cents: 1800,
        images: [
          "https://images.unsplash.com/photo-1591946614720-90a587da4a36?w=1200&q=80",
        ],
        hashtags: ["nails", "pets"],
        duration_minutes: 15,
      },
    ],
  },

  // ================================ EVENTS ==================================
  {
    handle: "sohowalks",
    business_name: "SoHo Art Walks Co.",
    category: "Tours & Events",
    description:
      "Curated walking tours through SoHo's gallery district. Limited groups (max 12), led by working artists and curators. Ends with a pour at a partner gallery.",
    logo_url:
      "https://images.unsplash.com/photo-1531058020387-3be344556be6?w=400&q=80",
    cover_url:
      "https://images.unsplash.com/photo-1577083552431-6e5fd01988ec?w=1400&q=80",
    services: ["Public tours", "Private tours", "Corporate events"],
    hashtags: ["art", "tour", "soho", "events", "galleries"],
    social_handles: {
      instagram: "sohoartwalks",
    },
    website: "https://sohoartwalks.example",
    phone: "+1-212-555-0166",
    hours: [
      { day_of_week: 0, open_time: "11:00", close_time: "17:00", is_closed: false },
      { day_of_week: 1, open_time: null, close_time: null, is_closed: true },
      { day_of_week: 2, open_time: null, close_time: null, is_closed: true },
      { day_of_week: 3, open_time: "13:00", close_time: "20:00", is_closed: false },
      { day_of_week: 4, open_time: "13:00", close_time: "20:00", is_closed: false },
      { day_of_week: 5, open_time: "11:00", close_time: "21:00", is_closed: false },
      { day_of_week: 6, open_time: "10:00", close_time: "21:00", is_closed: false },
    ],
    location: {
      lat: 40.7251,
      lng: -73.9985,
      address: "Mercer St & Prince St (meeting point), SoHo",
    },
    listings: [
      (() => {
        const start = inDays(3, 18);
        return {
          type: "event" as const,
          title: "First Thursday Gallery Crawl",
          description:
            "Three SoHo galleries in 90 minutes — we time it with First Thursday so most are open late. Includes a glass of natural wine at the third stop.",
          price_cents: 4500,
          images: [
            "https://images.unsplash.com/photo-1577083552431-6e5fd01988ec?w=1200&q=80",
          ],
          hashtags: ["art", "tour", "firstthursday"],
          capacity: 12,
          starts_at: start,
          ends_at: plusHours(start, 2),
        };
      })(),
      (() => {
        const start = inDays(10, 14);
        return {
          type: "event" as const,
          title: "Saturday Studio Visits",
          description:
            "Two private studio visits with working artists in cast-iron loft buildings. Snacks, conversation, no pressure.",
          price_cents: 6500,
          images: [
            "https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?w=1200&q=80",
          ],
          hashtags: ["studiovisit", "art"],
          capacity: 10,
          starts_at: start,
          ends_at: plusHours(start, 3),
        };
      })(),
      (() => {
        const start = inDays(21, 19);
        return {
          type: "event" as const,
          title: "After-Dark SoHo: Architecture & Light",
          description:
            "An hour of cast-iron facade photography after sunset. Bring any camera — we'll loan tripods if you need one.",
          price_cents: 5500,
          images: [
            "https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=1200&q=80",
          ],
          hashtags: ["photography", "architecture", "night"],
          capacity: 8,
          starts_at: start,
          ends_at: plusHours(start, 1.5),
        };
      })(),
    ],
    posts: [
      {
        content:
          "Two seats just opened for Thursday's gallery crawl — grab them on the listing.",
        images: [],
        hashtags: ["events", "soho"],
      },
    ],
  },
  {
    handle: "lateralsounds",
    business_name: "Lateral Sounds",
    category: "Music Venue",
    description:
      "A 60-seat listening room on Howard St. Live jazz, soul, and improv. Artist-first sound, two sets a night, no opening bands you didn't come to see.",
    logo_url:
      "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&q=80",
    cover_url:
      "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1400&q=80",
    services: ["Live shows", "Private events", "Album releases"],
    hashtags: ["music", "jazz", "soho", "live", "events"],
    social_handles: {
      instagram: "lateralsounds",
      tiktok: "lateralsounds",
    },
    website: "https://lateralsounds.example",
    phone: "+1-212-555-0199",
    hours: HOURS_EVENINGS,
    location: {
      lat: 40.7195,
      lng: -73.9988,
      address: "29 Howard St, New York, NY 10013",
    },
    listings: [
      (() => {
        const start = inDays(2, 20);
        return {
          type: "event" as const,
          title: "Friday Night Jazz: The Maya Trio",
          description:
            "Two sets, 8pm and 10pm. Cover includes one drink. Standing room behind the bar; tables sold separately.",
          price_cents: 3500,
          images: [
            "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1200&q=80",
          ],
          hashtags: ["jazz", "live", "friday"],
          capacity: 60,
          starts_at: start,
          ends_at: plusHours(start, 4),
        };
      })(),
      (() => {
        const start = inDays(7, 21);
        return {
          type: "event" as const,
          title: "Soul & Vinyl Wednesday",
          description:
            "DJ-led listening session, all-vinyl, all soul. Open turntable for the first hour — bring a 45.",
          price_cents: 2000,
          images: [
            "https://images.unsplash.com/photo-1471478331149-c72f17e33c73?w=1200&q=80",
          ],
          hashtags: ["soul", "vinyl", "djnight"],
          capacity: 60,
          starts_at: start,
          ends_at: plusHours(start, 4),
        };
      })(),
      (() => {
        const start = inDays(14, 19);
        return {
          type: "event" as const,
          title: "Album Release: Theo Park Quartet",
          description:
            "Theo's debut LP played front-to-back, then a Q&A. Limited LPs at the door, signed.",
          price_cents: 4500,
          images: [
            "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=1200&q=80",
          ],
          hashtags: ["albumrelease", "jazz", "live"],
          capacity: 60,
          starts_at: start,
          ends_at: plusHours(start, 3),
        };
      })(),
    ],
    posts: [
      {
        content:
          "Last 8 tickets for Friday's Maya Trio set — both shows almost sold.",
        images: [],
        hashtags: ["jazz", "live"],
      },
    ],
  },
];
