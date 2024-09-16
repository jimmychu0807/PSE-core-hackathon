"use client";

// 3rd-parties components
import { useWalletInfo } from "@web3modal/wagmi/react";
import { usePathname, useRouter } from "next/navigation";
import { Box, HStack, Icon, IconButton, Spinner, Text, VStack } from "@chakra-ui/react";
import { ChevronLeftIcon } from "@chakra-ui/icons";
import { Link } from "@chakra-ui/next-js";
import { FaGithub } from "react-icons/fa";

// Components defined in this repo
import { projectInfo } from "@/config";
import { useLogContext } from "@/context/LogContext";
import { Web3Connect } from "@/components";

function PromptForWalletConnect() {
  return (
    <VStack align="center" justify="center" height="80vh">
      <Text fontSize="xl">Please connect with your wallet</Text>
    </VStack>
  );
}

function Footer() {
  return (
    <Box
      position="fixed"
      bottom="0"
      left="0"
      right="0"
      bg="blue.800"
      color="white"
      p={2}
      textAlign="center"
    >
      <Text fontSize="xs">
        Made with ❤️ by&nbsp;
        <Link href={projectInfo.authorHomepage} isExternal textDecoration="underline">
          Jimmy Chu
        </Link>
        &nbsp; | Capstone Project of&nbsp;
        <Link href={projectInfo.psePage} isExternal textDecoration="underline">
          PSE Core Program
        </Link>
      </Text>
    </Box>
  );
}

function Header() {
  const router = useRouter();
  const pathname = usePathname();

  const isHome = pathname === "" || pathname === "/";

  return (
    <HStack align="center" justify="space-between" p="2">
      <Box>
        {!isHome && (
          <IconButton
            isRound={true}
            variant="ghost"
            size="lg"
            colorScheme="blue"
            aria-label="Back to Home"
            onClick={() => router.push("/")}
            icon={<ChevronLeftIcon />}
          />
        )}
      </Box>
      <HStack align="center" justify="right" p="2">
        <Link href={projectInfo.github} isExternal>
          <IconButton
            aria-label="Github repository"
            variant="link"
            py="3"
            color="text.100"
            icon={<Icon boxSize={6} as={FaGithub} />}
          />
        </Link>
        <Web3Connect />
      </HStack>
    </HStack>
  );
}

export default function PageContainer({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const { log } = useLogContext();
  const { walletInfo } = useWalletInfo();

  return (
    <VStack spacing={0} align="stretch" height="100vh">
      <Header />
      <Box flex="1" alignItems="center">
        {walletInfo ? <>{children}</> : <PromptForWalletConnect />}
        {log && (
          <HStack
            flexBasis="56px"
            borderTopWidth="1px"
            borderTopColor="text.600"
            backgroundColor="darkBlueBg"
            align="center"
            justify="center"
            spacing="4"
            p="4"
          >
            {log.endsWith("...") && <Spinner color="primary.400" />}
            <Text>{log}</Text>
          </HStack>
        )}
      </Box>
      <Footer />
    </VStack>
  );
}
