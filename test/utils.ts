export function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export const getLzEndpoint = (network: string) => {
  switch (network) {
    case "bscTestnet":
      return "0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1";
    case "arbitrumGoerli":
      return "0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab";
    case "mumbai":
      return "0xf69186dfBa60DdB133E91E9A4B5673624293d8F8";
    default:
      throw new Error("LayerZero endpoint address not found for the network");
  }
};

export const getAxelarGateway = (network: string): string => {
  switch (network) {
    case "bscTestnet":
      return "0x4D147dCb984e6affEEC47e44293DA442580A3Ec0";
    case "arbitrumGoerli":
      return "0xe432150cce91c13a887f7D836923d5597adD8E31";
    case "mumbai":
      return "0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B";
    default:
      throw new Error("Unsupported network");
  }
};

export const getAxelarGasService = (network: string): string => {
  switch (network) {
    case "bscTestnet":
      return "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6";
    case "arbitrumGoerli":
      return "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6";
    case "mumbai":
      return "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6";
    default:
      throw new Error("Unsupported network");
  }
};
