// import { HardhatUserConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox";
// // import "@typechain/hardhat"; // Этот импорт не нужен, т.к. Toolbox уже включает Typechain

// // --- 1. ДОБАВЬТЕ ЭТО ДЛЯ ЗАГРУЗКИ ПЕРЕМЕННЫХ ОКРУЖЕНИЯ ---
// import dotenv from "dotenv";
// dotenv.config();
// // ---------------------------------------------------------

// const config: HardhatUserConfig = {
//   solidity: "0.8.28",
//   networks: {
//     sepolia: {
//       url: process.env.SEPOLIA_RPC_URL || "", // Изменил имя переменной для ясности
//       accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
//       // --- 2. ДОБАВЬТЕ chainId ---
//       chainId: 11155111, // Chain ID для Sepolia
//       // --------------------------
//     },
//     // Опционально: если вы хотите форкнуть Sepolia для локальных тестов
//     // hardhat: {
//     //   forking: {
//     //     url: process.env.SEPOLIA_RPC_URL || "",
//     //     blockNumber: 5000000, // Рекомендуется указать blockNumber для стабильности форка
//     //   }
//     // }
//   },
//   etherscan: {
//     apiKey: {
//       sepolia: process.env.ETHERSCAN_API_KEY as string,
//     },
//   },
//   // --- 3. ОПЦИОНАЛЬНО: Явная конфигурация Typechain ---
//   typechain: {
//     outDir: "typechain-types", // Убедитесь, что это совпадает с вашим использованием
//     target: "ethers-v6", // Используйте 'ethers-v5' если вы работаете с ethers v5
//   },
//   // ----------------------------------------------------
// };

// export default config;
// import { HardhatUserConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox";
// // import "@typechain/hardhat"; // Этот импорт не нужен, т.к. Toolbox уже включает Typechain

// // // --- 1. ДОБАВЬТЕ ЭТО ДЛЯ ЗАГРУЗКИ ПЕРЕМЕННЫХ ОКРУЖЕНИЯ ---
// import dotenv from "dotenv";
// dotenv.config();
// // ---------------------------------------------------------

// const config: HardhatUserConfig = {
//   // Убедитесь, что эта версия Solidity совпадает с версией в ваших контрактах!
//   solidity: "0.8.28", // Или "0.8.26", если ваш контракт использует ее
//   networks: {
//     sepolia: {
//       // --- ИСПРАВЛЕНИЕ: Добавлен оператор || ---
//       url: process.env.SEPOLIA_RPC_URL || "", // Изменил имя переменной для ясности
//       accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
//       // --- 2. ДОБАВЬТЕ chainId ---
//       chainId: 11155111, // Chain ID для Sepolia
//       // --------------------------
//     },
//     // Опционально: если вы хотите форкнуть Sepolia для локальных тестов
//     // hardhat: {
//     //   forking: {
//     //     // Убедитесь, что SEPOLIA_RPC_URL в .env имеет достаточно высокий rate limit,
//     //     // иначе форкинг может быть нестабилен.
//     //     url: process.env.SEPOLIA_RPC_URL || "",
//     //     // blockNumber: 5000000, // Рекомендуется указать blockNumber для стабильности форка
//     //     // Если не указать blockNumber, будет форкнут последний блок,
//     //     // что может быть удобно, но может привести к разным результатам тестов
//     //     // при повторных запусках из-за меняющегося состояния.
//     //   }
//     // }
//   },
//   etherscan: {
//     apiKey: {
//       // Это безопасно, т.к. dotenv.config() уже гарантирует, что переменные доступны.
//       // Однако, если ETHERSCAN_API_KEY отсутствует, это может привести к ошибке при развертывании/верификации.
//       sepolia: process.env.ETHERSCAN_API_KEY || "", // Добавил || "" для большей устойчивости
//     },
//   },
//   // --- 3. ОПЦИОНАЛЬНО: Явная конфигурация Typechain ---
//   typechain: {
//     outDir: "typechain-types", // Убедитесь, что это совпадает с вашим использованием
//     target: "ethers-v6", // Используйте 'ethers-v5' если вы работаете с ethers v5
//   },
//   // ----------------------------------------------------
// };

// export default config;
// hardhat.config.js или hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      forking: {
        url: process.env.SEPOLIA_RPC_URL || "",
      },
    },
    sepolia: { // Эта секция нужна для развертывания, но не для forking тестов
      url: process.env.SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155111,
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY || "",
    },
  },
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v6",
  },
};

export default config;