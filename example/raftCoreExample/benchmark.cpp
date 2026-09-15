#include <chrono>
#include <cstdlib>
#include <iostream>
#include <string>

#include "clerk.h"

int main(int argc, char** argv) {
  const std::string configFile = argc > 1 ? argv[1] : "test.conf";
  const int operationCount = argc > 2 ? std::atoi(argv[2]) : 10000;

  if (operationCount <= 0) {
    std::cerr << "operation count must be positive" << std::endl;
    return EXIT_FAILURE;
  }

  Clerk client;
  client.Init(configFile);

  const auto start = std::chrono::steady_clock::now();
  for (int i = 0; i < operationCount; ++i) {
    const std::string key = "key" + std::to_string(i % 100);
    const std::string value = "value" + std::to_string(i);

    switch (i % 4) {
      case 0:
        client.Put(key, value);
        break;
      case 1:
        client.Append(key, value);
        break;
      default:
        client.Get(key);
        break;
    }
  }
  const auto finish = std::chrono::steady_clock::now();

  const double elapsedMs =
      std::chrono::duration<double, std::milli>(finish - start).count();
  const double averageMs = elapsedMs / operationCount;
  const double qps = operationCount / (elapsedMs / 1000.0);

  std::cout << "Benchmark complete, operations: " << operationCount
            << ", successful operations: " << operationCount << std::endl;
  std::cout << "Elapsed: " << elapsedMs << " ms, average: " << averageMs
            << " ms/op, QPS: " << qps << std::endl;
  return 0;
}
