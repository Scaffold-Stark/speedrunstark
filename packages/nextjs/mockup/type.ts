interface InputURL {
  id: string;
  title: string;
  placeholder: string;
}

export type Challenge = {
  id: string;
  name: string;
  isBurn?: boolean;
  comming?: boolean;
  challenge: string;
  inputURL?: InputURL[];
};
