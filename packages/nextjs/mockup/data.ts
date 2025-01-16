export const ROADMAP_DETAIL_DATA = [
  {
    id: "learn",
    title: "COMPLETE SPEEDRUN STARK",
    number: 1,
    desc: "Learn how to build on Starknet and discover its superpowers and gotchas. Start your journey by watching our foundational videos, practice with Starklings, solve Speedrun Challenges, and finally ship your first dApp.",
    xUrl: "",
  },
  {
    id: "build",
    title: "Join a hackathon",
    number: 2,
    desc: "Dive into a collaborative and high-energy environment where innovation thrives. Hackathons offer an opportunity to showcase your technical and creative skills, build a prototype, and solve real-world problems alongside like-minded individuals. It's the perfect stage to launch your ideas into action.",
    xUrl: "",
  },
  {
    id: "hack",
    title: "Connect at Hacker House",
    number: 3,
    desc: "Expand your network by engaging with a community of builders, developers, and visionaries at Hacker House events. Share knowledge, gather feedback, and form strategic partnerships to refine your project and align with industry trends.",
    xUrl: "",
  },
  {
    id: "seed",
    title: "Apply for Seed Funding",
    number: 4,
    desc: "Turn your vision into reality by securing initial capital. With a polished pitch and a well-thought-out business model, approach investors and accelerators that align with your goals. Seed funding will fuel the next stage of development and growth.",
    xUrl: "",
  },
  {
    id: "demo",
    title: "Present at Demo Day",
    number: 5,
    desc: "Showcase your progress and potential to a room filled with investors, mentors, and industry leaders. Use this opportunity to demonstrate traction, share your vision, and captivate stakeholders to take your project to the next level.",
    xUrl: "",
  },
  {
    id: "fund",
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
  },
  {
    icon: "/homescreen/mustwatch.png",
    name: "Must Watch",
    type: "video",
  },
  {
    icon: "/homescreen/roadmap.png",
    name: "Roadmap",
    type: "roadmap",
  },
  {
    icon: "/homescreen/starklings.png",
    name: "starklings",
    type: "starklings",
  },
  {
    icon: "/homescreen/readme.png",
    name: "read_me",
    type: "readme",
  },
] as const;

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
  },
  {
    id: "challenge-1-decentralized-staking",
    name: "Decentralized Staking App",
    isBurn: true,
  },
  {
    id: "challenge-2-token-vendor",
    name: "Token Vendor",
    isBurn: true,
  },
  {
    id: "challenge-3-dice-game",
    name: "Dice Game",
    isBurn: true,
  },
  {
    id: "build-a-dex",
    name: "Build a DEX",
    comming: true,
  },
  {
    id: "state-channel-application",
    name: "A State Channel Application",
    comming: true,
  },
  {
    id: "multisig-wallet-challenge",
    name: "Multisig Wallet Challenge",
    comming: true,
  },
  {
    id: "svg-nft",
    name: "Building Cohort Challenge",
    comming: true,
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
    date: "19/09/2023",
    desc: "In this video we cover why Cairo is a unique programming language, how Starknet solves Ethereum's scalability problem, how zero knowledge proofs are used, a high level overview of Starknet's architecture and we do a live example of how to use a wallet, a bridge and a block explorer.",
    banner: "/homescreen/video-section1.png",
    url: "https://youtu.be/8GH92wM4jB0?list=PLMXIoXErTTYX-ZSxlaYDxsR66l5a39IwA",
  },
  {
    title: "Session 2: architecture",
    date: "19/09/2023",
    desc: "In this session we learn about Cairo’s syntax by solving Starklings, an interactive tutorial created by the community and inspired by Rustlings.",
    banner: "/homescreen/video-section1.png",
    url: "https://youtu.be/ofyhpQYTycs?list=PLMXIoXErTTYX-ZSxlaYDxsR66l5a39IwA",
  },
  {
    title: "Session 3: cairo",
    date: "22/09/2023",
    desc: "In this session, Pierre shows how to write a Starknet smart contract from scratch, how to deploy it to Katana for local testing and how to deploy it to Starknet’s testnet using Starkli.",
    banner: "/homescreen/video-section1.png",
    url: "https://youtu.be/6oSHviHTTOo?list=PLMXIoXErTTYX-ZSxlaYDxsR66l5a39IwA",
  },
];
