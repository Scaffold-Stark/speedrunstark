import axios from "axios";

export const getCompletedChallenges = async (
  address: string,
): Promise<any[]> => {
  return new Promise((resolve, reject) => {
    axios
      .get(`${process.env.NEXT_PUBLIC_SERVER_BASE_URL}/challenges/${address}`)
      .then((response) => {
        if (
          response &&
          response.data &&
          response.data.completedChallenges &&
          Array.isArray(response.data.completedChallenges)
        ) {
          resolve(response.data.completedChallenges);
        } else {
          reject("request unknown error");
        }
      })
      .catch((error) => {
        reject(error);
      });
  });
};
