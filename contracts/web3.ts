
import { createWalletClient, createPublicClient, http, parseEther, getAddress } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';
import * as dotenv from 'dotenv';
import { mnemonicToAccount } from 'viem/accounts'
dotenv.config();

// Вместо генерации, используем мнемоническую фразу
const mnemonicPhrase = "day what chunk learn coast guide mother float clump ship latin horn tobacco attack mom";

// Создаем аккаунт из мнемонической фразы
const account = mnemonicToAccount(mnemonicPhrase);

// Загрузка переменных окружения
const rpcUrl = process.env.RPC_URL;
const receiverAddress = process.env.RECEIVER_ADDRESS as `0x${string}`;

// Проверка наличия переменных окружения
if (!rpcUrl || !receiverAddress) {
    throw new Error("Missing environment variables. Check .env.");
}

// Настройка клиентов
const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(rpcUrl),
});

const walletClient = createWalletClient({
    chain: sepolia,
    transport: http(rpcUrl),
    account: account,
});

async function main() {
    // Запрос цены газа
    const gasPrice = await publicClient.getGasPrice();
    console.log("Gas Price:", gasPrice);

    // Запрос баланса ETH
    const balance = await publicClient.getBalance({ address: account.address });
    console.log("Balance:", balance);

    try {
        // Оцениваем газ
        const gasEstimate = await publicClient.estimateGas({
            account: account.address,
            to: receiverAddress,
            value: parseEther("0.0001"),
        });

        // Отправляем транзакцию
        const hash = await walletClient.sendTransaction({
            to: receiverAddress,
            value: parseEther("0.0001"),
            gas: gasEstimate * 2n,
            maxFeePerGas: gasPrice * 2n,
            maxPriorityFeePerGas: gasPrice,
        });

        console.log("Transaction Hash:", hash);

        // Ожидаем подтверждения
        const transactionReceipt = await publicClient.waitForTransactionReceipt({ hash });
        if (transactionReceipt.status === 'success') {
            console.log("Transaction successful!");
        } else {
            console.error("Transaction failed.");
        }
    } catch (error) {
        console.error("Error:", error);
    }
}

main().catch((error) => {
    console.error(error);
});