export const ROADMAP_DETAIL_DATA = [
  {
    id: "learn",
    icon: "/homescreen/roadmap-learn.svg",
    title: "COMPLETE SPEEDRUN STARK",
    number: 1,
    desc: "Learn how to build on Starknet and discover its superpowers and gotchas. Start your journey by watching our foundational videos, practice with Starklings, solve Speedrun Challenges, and finally ship your first dApp.",
    xUrl: "",
  },
  {
    id: "build",
    icon: "/homescreen/roadmap-build.svg",
    title: "Join a hackathon",
    number: 2,
    desc: "Dive into a collaborative and high-energy environment where innovation thrives. Hackathons offer an opportunity to showcase your technical and creative skills, build a prototype, and solve real-world problems alongside like-minded individuals. It's the perfect stage to launch your ideas into action.",
    xUrl: "",
  },
  {
    id: "hack",
    icon: "/homescreen/roadmap-hack.svg",
    title: "Connect at Hacker House",
    number: 3,
    desc: "Expand your network by engaging with a community of builders, developers, and visionaries at Hacker House events. Share knowledge, gather feedback, and form strategic partnerships to refine your project and align with industry trends.",
    xUrl: "",
  },
  {
    id: "seed",
    icon: "/homescreen/roadmap-seed.svg",
    title: "Apply for Seed Funding",
    number: 4,
    desc: "Turn your vision into reality by securing initial capital. With a polished pitch and a well-thought-out business model, approach investors and accelerators that align with your goals. Seed funding will fuel the next stage of development and growth.",
    xUrl: "",
  },
  {
    id: "demo",
    icon: "/homescreen/roadmap-demo.svg",
    title: "Present at Demo Day",
    number: 5,
    desc: "Showcase your progress and potential to a room filled with investors, mentors, and industry leaders. Use this opportunity to demonstrate traction, share your vision, and captivate stakeholders to take your project to the next level.",
    xUrl: "",
  },
  {
    id: "fund",
    icon: "/homescreen/roadmap-fund.svg",
    title: "Raise Funds",
    number: 6,
    desc: "Build on the momentum from Demo Day by engaging with investors, negotiating terms, and finalizing deals. Secure the funding needed to scale your operations, expand your team, and establish your presence in the market. Each step brings you closer to long-term success.",
    xUrl: "",
  },
];

export const DATA_MENU = [
  {
    icon: "/homescreen/challenges.png",
    name: "Challenges",
    type: "challenge",
    url: "",
  },
  {
    icon: "/homescreen/mustwatch.png",
    name: "Must Watch",
    type: "video",
    url: "",
  },
  {
    icon: "/homescreen/roadmap.png",
    name: "Roadmap",
    type: "roadmap",
    url: "",
  },
  {
    icon: "/homescreen/starklings.png",
    name: "starklings",
    type: "starklings",
    url: "https://starklings.app/",
  },
  {
    icon: "/homescreen/readme.png",
    name: "read_me",
    type: "readme",
    url: "",
  },
] as const;

export const DATA_MENU_BOT = [
  {
    icon: "/homescreen/mustwatch.png",
    name: "Must Watch",
    type: "video",
    url: "",
  },
  {
    icon: "/homescreen/starklings.png",
    name: "starklings",
    type: "starklings",
    url: "https://starklings.app/",
  },

  {
    icon: "/homescreen/readme.png",
    name: "read_me",
    type: "readme",
    url: "",
  },
  {
    icon: "/homescreen/roadmap.png",
    name: "Roadmap",
    type: "roadmap",
    url: "",
  },
];

export const DATA_MENU_SOCIAL = [
  {
    icon: "/homescreen/telegram.png",
    name: "Telegram",
    type: "telegram",
    url: "https://t.me/+wO3PtlRAreo4MDI9",
  },
  {
    icon: "/homescreen/x.png",
    name: "X_social",
    type: "x_social",
    url: "https://twitter.com/ScaffoldStark",
  },
];

export const DATA_JOURNEY = [
  "Watch our foundational videos",
  "Practice with Starklings",
  "Solve Speedrun Challenges",
  "Ship your first dApp",
];

export const DATA_CHALLENGE_V2 = [
  {
    id: "challenge-0-simple-nft",
    name: "Simple NFT Example",
    isBurn: true,
    challenge: "Challenge #0",
    inputURL: [
      {
        id: "deployed",
        title: "Enter Deployed URL",
        placeholder: "Enter deployed URL...",
      },
      {
        id: "sc",
        title: "Enter Deployed Smart Contract",
        placeholder: "Enter contract...",
      },
      {
        id: "github",
        title: "Enter Github URL",
        placeholder: "Enter Github URL...",
      },
    ],
  },
  {
    id: "challenge-1-decentralized-staking",
    name: "Decentralized Staking App",
    isBurn: true,
    challenge: "Challenge #1",
    inputURL: [
      {
        id: "deployed",
        title: "Enter Deployed URL",
        placeholder: "Enter deployed URL...",
      },
      {
        id: "staker",
        title: "Enter Staker Contract",
        placeholder: "Enter staker contract...",
      },
      {
        id: "github",
        title: "Enter Github URL",
        placeholder: "Enter Github URL...",
      },
    ],
  },
  {
    id: "challenge-2-token-vendor",
    name: "Token Vendor",
    isBurn: true,
    challenge: "Challenge #2",
    inputURL: [
      {
        id: "deployed",
        title: "Enter Deployed URL",
        placeholder: "Enter deployed URL...",
      },
      {
        id: "vendor",
        title: "Enter Vendor Contract",
        placeholder: "Enter vendor contract...",
      },
      {
        id: "github",
        title: "Enter Github URL",
        placeholder: "Enter Github URL...",
      },
    ],
  },
  {
    id: "challenge-3-dice-game",
    name: "Dice Game",
    isBurn: true,
    challenge: "Challenge #3",
    inputURL: [
      {
        id: "deployed",
        title: "Enter Deployed URL",
        placeholder: "Enter deployed URL...",
      },
      {
        id: "dicegame",
        title: "Enter Dice Game Contract",
        placeholder: "Enter Dice Game contract...",
      },
      {
        id: "github",
        title: "Enter Github URL",
        placeholder: "Enter Github URL...",
      },
    ],
  },
  {
    id: "build-a-dex",
    name: "Build a DEX",
    comming: true,
    challenge: "Challenge #4",
  },
  {
    id: "state-channel-application",
    name: "A State Channel Application",
    comming: true,
    challenge: "Challenge #5",
  },
  {
    id: "multisig-wallet-challenge",
    name: "Multisig Wallet Challenge",
    comming: true,
    challenge: "Challenge #6",
  },
  {
    id: "svg-nft",
    name: "Building Cohort Challenge",
    comming: true,
    challenge: "Challenge #7",
  },
];

export const DATA_LANGUAGE = [
  {
    title: "HELLO",
    language: "ENGLISH",
  },
  {
    title: "你好",
    language: "Chinese",
  },
  {
    title: "HOLA",
    language: "SPANISH",
  },
];

export const DATA_VIDEOS = [
  {
    title: "Session 1: Fundamentals",
    date: "16/01/2025",
    desc: "Welcome to the first session of Basecamp 11, focused on Starknet fundamentals. This session provides a clear overview of Starknet, covering its ecosystem, the Cairo programming language, Starknet's role in blockchain scalability, smart wallets, and its architecture. Ideal for those looking to get a solid introduction to Starknet without the hype.",
    banner: "/homescreen/video-session1.jpg",
    url: "https://www.youtube.com/watch?v=ha_K3P1OWi0",
  },
  {
    title: "Session 2: Smart Contracts",
    date: "16/01/2025",
    desc: "In this session, we build a counter smart contract that allows safe counter manipulation, emits events on changes, and prevents underflow and overflow. Participants will engage in a detailed walkthrough of the counter-workshop, and gain hands-on experience deploying a contract to the testnet.",
    banner: "/homescreen/video-session2.jpg",
    url: "https://www.youtube.com/watch?v=Eljq246SdC0",
  },
  {
    title: "Session 3: Testing",
    date: "16/01/2025",
    desc: "In this session, we continue with the same code from the previous class and create tests for each use case. This live coding session is aimed at solidifying the skills and concepts covered in previous sessions.",
    banner: "/homescreen/video-session3.jpg",
    url: "https://www.youtube.com/watch?v=acH0gObykXg",
  },
  {
    title: "Session 4: Frontend",
    date: "16/01/2025",
    desc: "In this hands-on session, we'll dive into frontend development, building a decentralized application (dApp) with React, Next.js, and the Starknet-React library. We'll cover reading and writing to smart contracts, fetching blockchain data, and essential concepts for creating a user-friendly Starknet frontend.",
    banner: "/homescreen/video-session4.jpg",
    url: "https://www.youtube.com/watch?v=9FdFEb86oCE",
  },
];

export const DATA_WALLET = [
  {
    icon: "/homescreen/argent.png",
    name: "Argent",
  },
  {
    icon: "/homescreen/braavos.png",
    name: "Braavos",
  },
];
