#include <iostream>
#include <set>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <iomanip>
#include <unistd.h>
#include <cuda_runtime.h>
#include <atomic>
#include <cuda/atomic>
#include "litmus.cuh"

typedef struct {
  int numMemLocations;
  int permuteLocation;
} TestParams;

typedef struct {
  int testIterations;
  int testingWorkgroups;
  int maxWorkgroups;
  int workgroupSize;
  int shufflePct;
  int barrierPct;
  int stressLineSize;
  int stressTargetLines;
  int scratchMemorySize;
  int memStride;
  int memStressPct;
  int memStressIterations;
  int memStressPattern;
  int preStressPct;
  int preStressIterations;
  int preStressPattern;
  int stressAssignmentStrategy;
  int permuteThread;
} StressParams;

void checkCuda(cudaError_t status, const char* operation) {
  if (status != cudaSuccess) {
    std::cerr << operation << " failed: " << cudaGetErrorString(status) << "\n";
    exit(1);
  }
}

int parseTestParamsFile(const char* filename, TestParams* config) {
  FILE* file = fopen(filename, "r");
  if (file == NULL) {
    perror("Error opening file");
    return -1;
  }

  char line[256];
  while (fgets(line, sizeof(line), file)) {
    char key[64];
    int value;
    if (sscanf(line, "%63[^=]=%d", key, &value) == 2) {
      if (strcmp(key, "numMemLocations") == 0) config->numMemLocations = value;
      else if (strcmp(key, "permuteLocation") == 0) config->permuteLocation = value;
    }
  }

  fclose(file);
  return 0;
}

int parseStressParamsFile(const char* filename, StressParams* config) {
  FILE* file = fopen(filename, "r");
  if (file == NULL) {
    perror("Error opening file");
    return -1;
  }

  char line[256];
  while (fgets(line, sizeof(line), file)) {
    char key[64];
    int value;
    if (sscanf(line, "%63[^=]=%d", key, &value) == 2) {
      if (strcmp(key, "testIterations") == 0) config->testIterations = value;
      else if (strcmp(key, "testingWorkgroups") == 0) config->testingWorkgroups = value;
      else if (strcmp(key, "maxWorkgroups") == 0) config->maxWorkgroups = value;
      else if (strcmp(key, "workgroupSize") == 0) config->workgroupSize = value;
      else if (strcmp(key, "shufflePct") == 0) config->shufflePct = value;
      else if (strcmp(key, "barrierPct") == 0) config->barrierPct = value;
      else if (strcmp(key, "stressLineSize") == 0) config->stressLineSize = value;
      else if (strcmp(key, "stressTargetLines") == 0) config->stressTargetLines = value;
      else if (strcmp(key, "scratchMemorySize") == 0) config->scratchMemorySize = value;
      else if (strcmp(key, "memStride") == 0) config->memStride = value;
      else if (strcmp(key, "memStressPct") == 0) config->memStressPct = value;
      else if (strcmp(key, "memStressIterations") == 0) config->memStressIterations = value;
      else if (strcmp(key, "memStressPattern") == 0) config->memStressPattern = value;
      else if (strcmp(key, "preStressPct") == 0) config->preStressPct = value;
      else if (strcmp(key, "preStressIterations") == 0) config->preStressIterations = value;
      else if (strcmp(key, "preStressPattern") == 0) config->preStressPattern = value;
      else if (strcmp(key, "stressAssignmentStrategy") == 0) config->stressAssignmentStrategy = value;
      else if (strcmp(key, "permuteThread") == 0) config->permuteThread = value;
    }
  }

  fclose(file);
  return 0;
}

/** Returns a value between the min and max (inclusive). */
int setBetween(int min, int max) {
  if (min == max) {
    return min;
  }
  else {
    int size = rand() % (max - min + 1);
    return min + size;
  }
}

bool percentageCheck(int percentage) {
  return rand() % 100 < percentage;
}

/** Assigns shuffled workgroup ids, using the shufflePct to determine whether the ids should be shuffled this iteration. */
void setShuffledWorkgroups(uint* h_shuffledWorkgroups, int numWorkgroups, int shufflePct) {
  for (int i = 0; i < numWorkgroups; i++) {
    h_shuffledWorkgroups[i] = i;
  }
  if (percentageCheck(shufflePct)) {
    for (int i = numWorkgroups - 1; i > 0; i--) {
      int swap = rand() % (i + 1);
      int temp = h_shuffledWorkgroups[i];
      h_shuffledWorkgroups[i] = h_shuffledWorkgroups[swap];
      h_shuffledWorkgroups[swap] = temp;
    }
  }
}

/** Sets the stress regions and the location in each region to be stressed. Uses the stress assignment strategy to assign
  * workgroups to specific stress locations. Assignment strategy 0 corresponds to a "round-robin" assignment where consecutive
  * threads access separate scratch locations, while assignment strategy 1 corresponds to a "chunking" assignment where a group
  * of consecutive threads access the same location.
  */
void setScratchLocations(uint* h_locations, int numWorkgroups, StressParams params) {
  std::set<int> usedRegions;
  int numRegions = params.scratchMemorySize / params.stressLineSize;
  for (int i = 0; i < params.stressTargetLines; i++) {
    int region = rand() % numRegions;
    while (usedRegions.count(region))
      region = rand() % numRegions;
    int locInRegion = rand() % params.stressLineSize;
    switch (params.stressAssignmentStrategy) {
    case 0:
      for (int j = i; j < numWorkgroups; j += params.stressTargetLines) {
        h_locations[j] = (region * params.stressLineSize) + locInRegion;
      }
      break;
    case 1:
      int workgroupsPerLocation = numWorkgroups / params.stressTargetLines;
      for (int j = 0; j < workgroupsPerLocation; j++) {
        h_locations[i * workgroupsPerLocation + j] = (region * params.stressLineSize) + locInRegion;
      }
      if (i == params.stressTargetLines - 1 && numWorkgroups % params.stressTargetLines != 0) {
        for (int j = 0; j < numWorkgroups % params.stressTargetLines; j++) {
          h_locations[numWorkgroups - j - 1] = (region * params.stressLineSize) + locInRegion;
        }
      }
      break;
    }
  }
}

/** These parameters vary per iteration, based on a given percentage. */
void setDynamicKernelParams(KernelParams* h_kernelParams, StressParams params) {
  h_kernelParams->barrier = percentageCheck(params.barrierPct);
  h_kernelParams->mem_stress = percentageCheck(params.memStressPct);
  h_kernelParams->pre_stress = percentageCheck(params.preStressPct);
}

/** These parameters are static for all iterations of the test. */
void setStaticKernelParams(KernelParams* h_kernelParams, StressParams stressParams, TestParams testParams) {
  h_kernelParams->mem_stress_iterations = stressParams.memStressIterations;
  h_kernelParams->mem_stress_pattern = stressParams.memStressPattern;
  h_kernelParams->pre_stress_iterations = stressParams.preStressIterations;
  h_kernelParams->pre_stress_pattern = stressParams.preStressPattern;
  h_kernelParams->permute_thread = stressParams.permuteThread;
  h_kernelParams->permute_location = testParams.permuteLocation;
  h_kernelParams->testing_workgroups = stressParams.testingWorkgroups;
  h_kernelParams->mem_stride = stressParams.memStride;
  h_kernelParams->mem_offset = stressParams.memStride;
}

uint64_t total_behaviors(TestResults * results) {
  return static_cast<uint64_t>(results->res0) + results->res1 + results->res2 + results->res3 +
  results->res4 + results->res5 + results->res6 + results->res7 +
  results->res8 + results->res9 + results->res10 + results->res11 +
  results->res12 + results->res13 + results->res14 + results->res15 +
  results->weak + results->other;
}


void run(StressParams stressParams, TestParams testParams, bool print_results) {
  int testingThreads = stressParams.workgroupSize * stressParams.testingWorkgroups;

  int testLocSize = testingThreads * testParams.numMemLocations * stressParams.memStride * sizeof(uint);
  d_atomic_uint* testLocations;
  checkCuda(cudaMalloc(&testLocations, testLocSize), "cudaMalloc(testLocations)");

  int readResultsSize = sizeof(ReadResults) * testingThreads;
  ReadResults* readResults;
  checkCuda(cudaMalloc(&readResults, readResultsSize), "cudaMalloc(readResults)");

  TestResults* h_testResults = (TestResults*)malloc(sizeof(TestResults));
  TestResults* d_testResults;
  checkCuda(cudaMalloc(&d_testResults, sizeof(TestResults)), "cudaMalloc(d_testResults)");

  int shuffledWorkgroupsSize = stressParams.maxWorkgroups * sizeof(uint);
  uint* h_shuffledWorkgroups = (uint*)malloc(shuffledWorkgroupsSize);
  uint* d_shuffledWorkgroups;
  checkCuda(cudaMalloc(&d_shuffledWorkgroups, shuffledWorkgroupsSize), "cudaMalloc(d_shuffledWorkgroups)");

  int barrierSize = sizeof(uint);
  cuda::atomic<uint, cuda::thread_scope_device>* barrier;
  checkCuda(cudaMalloc(&barrier, barrierSize), "cudaMalloc(barrier)");

  int scratchpadSize = stressParams.scratchMemorySize * sizeof(uint);
  uint* scratchpad;
  checkCuda(cudaMalloc(&scratchpad, scratchpadSize), "cudaMalloc(scratchpad)");

  int scratchLocationsSize = stressParams.maxWorkgroups * sizeof(uint);
  uint* h_scratchLocations = (uint*)malloc(scratchLocationsSize);
  uint* d_scratchLocations;
  checkCuda(cudaMalloc(&d_scratchLocations, scratchLocationsSize), "cudaMalloc(d_scratchLocations)");

  KernelParams* h_kernelParams = (KernelParams*)malloc(sizeof(KernelParams));
  KernelParams* d_kernelParams;
  checkCuda(cudaMalloc(&d_kernelParams, sizeof(KernelParams)), "cudaMalloc(d_kernelParams)");
  setStaticKernelParams(h_kernelParams, stressParams, testParams);

  int testInstancesSize = sizeof(TestInstance) * testingThreads;
  TestInstance* h_testInstances = (TestInstance*)malloc(testInstancesSize);
  TestInstance* d_testInstances;
  checkCuda(cudaMalloc(&d_testInstances, testInstancesSize), "cudaMalloc(d_testInstances)");

  int weakSize = sizeof(bool) * testingThreads;
  bool* h_weak = (bool*)malloc(weakSize);
  bool* d_weak;
  checkCuda(cudaMalloc(&d_weak, weakSize), "cudaMalloc(d_weak)");

  // run iterations
  std::chrono::time_point<std::chrono::system_clock> start, end;
  start = std::chrono::system_clock::now();
  uint64_t weakBehaviors = 0;
  uint64_t totalBehaviors = 0;

  for (int i = 0; i < stressParams.testIterations; i++) {
    int numWorkgroups = setBetween(stressParams.testingWorkgroups, stressParams.maxWorkgroups);

    // clear memory
    checkCuda(cudaMemset(testLocations, 0, testLocSize), "cudaMemset(testLocations)");
    checkCuda(cudaMemset(d_testResults, 0, sizeof(TestResults)), "cudaMemset(d_testResults)");
    checkCuda(cudaMemset(readResults, 0, readResultsSize), "cudaMemset(readResults)");
    checkCuda(cudaMemset(barrier, 0, barrierSize), "cudaMemset(barrier)");
    checkCuda(cudaMemset(scratchpad, 0, scratchpadSize), "cudaMemset(scratchpad)");
    checkCuda(cudaMemset(d_testInstances, 0, testInstancesSize), "cudaMemset(d_testInstances)");
    checkCuda(cudaMemset(d_weak, false, weakSize), "cudaMemset(d_weak)");

    setShuffledWorkgroups(h_shuffledWorkgroups, numWorkgroups, stressParams.shufflePct);
    checkCuda(cudaMemcpy(d_shuffledWorkgroups, h_shuffledWorkgroups, shuffledWorkgroupsSize, cudaMemcpyHostToDevice), "cudaMemcpy(d_shuffledWorkgroups)");
    setScratchLocations(h_scratchLocations, numWorkgroups, stressParams);
    checkCuda(cudaMemcpy(d_scratchLocations, h_scratchLocations, scratchLocationsSize, cudaMemcpyHostToDevice), "cudaMemcpy(d_scratchLocations)");
    setDynamicKernelParams(h_kernelParams, stressParams);
    checkCuda(cudaMemcpy(d_kernelParams, h_kernelParams, sizeof(KernelParams), cudaMemcpyHostToDevice), "cudaMemcpy(d_kernelParams)");

    litmus_test << <numWorkgroups, stressParams.workgroupSize >> > (testLocations, readResults, d_shuffledWorkgroups, barrier, scratchpad, d_scratchLocations, d_kernelParams, d_testInstances);
    checkCuda(cudaGetLastError(), "litmus_test launch");
    checkCuda(cudaDeviceSynchronize(), "litmus_test synchronize");

    check_results << <stressParams.testingWorkgroups, stressParams.workgroupSize >> > (testLocations, readResults, d_testResults, d_kernelParams, d_weak);
    checkCuda(cudaGetLastError(), "check_results launch");
    checkCuda(cudaDeviceSynchronize(), "check_results synchronize");

    checkCuda(cudaMemcpy(h_testResults, d_testResults, sizeof(TestResults), cudaMemcpyDeviceToHost), "cudaMemcpy(h_testResults)");
    checkCuda(cudaMemcpy(h_testInstances, d_testInstances, testInstancesSize, cudaMemcpyDeviceToHost), "cudaMemcpy(h_testInstances)");
    checkCuda(cudaMemcpy(h_weak, d_weak, weakSize, cudaMemcpyDeviceToHost), "cudaMemcpy(h_weak)");

    if (print_results) {
      std::cout << "Iteration " << i << "\n";
      for (uint i = 0; i < testingThreads; i++) {
        if (h_weak[i]) {
          std::cout << "Weak result " << i << "\n";
          std::cout << "  t0: " << h_testInstances[i].t0;
          std::cout << "  t1: " << h_testInstances[i].t1;
          std::cout << "  t2: " << h_testInstances[i].t2;
          std::cout << "  t3: " << h_testInstances[i].t3 << "\n";

          std::cout << "  x: " << h_testInstances[i].x;
          std::cout << "  y: " << h_testInstances[i].y;
          std::cout << "  z: " << h_testInstances[i].z << "\n";

        }
      }
    }
    weakBehaviors += static_cast<uint64_t>(host_check_results(h_testResults, print_results));
    totalBehaviors += total_behaviors(h_testResults);
  }

  end = std::chrono::high_resolution_clock::now();
  std::chrono::duration<float> duration = end - start;
  std::cout << "Time taken: " << duration.count() << " seconds" << std::endl;
  std::cout << std::fixed << std::setprecision(0) << "Weak behavior rate: " << static_cast<double>(weakBehaviors) / duration.count() << " per second\n";

  std::cout << "Total behaviors: " << totalBehaviors << "\n";
  std::cout << "Number of weak behaviors: " << weakBehaviors << "\n";

  // Free memory
  cudaFree(testLocations);
  cudaFree(readResults);
  cudaFree(d_testResults);
  free(h_testResults);
  cudaFree(d_shuffledWorkgroups);
  free(h_shuffledWorkgroups);
  cudaFree(barrier);
  cudaFree(scratchpad);
  cudaFree(d_scratchLocations);
  free(h_scratchLocations);
  cudaFree(d_kernelParams);
  free(h_kernelParams);
  cudaFree(d_testInstances);
  free(h_testInstances);
  cudaFree(d_weak);
  free(h_weak);
}

int main(int argc, char* argv[]) {
  char* stress_params_file = nullptr;
  char* test_params_file = nullptr;
  bool print_results = false;

  int c;
  while ((c = getopt(argc, argv, "xs:t:")) != -1)
    switch (c)
    {
    case 's':
      stress_params_file = optarg;
      break;
    case 't':
      test_params_file = optarg;
      break;
    case 'x':
      print_results = true;
      break;
    case '?':
      if (optopt == 's' || optopt == 't')
        std::cerr << "Option -" << optopt << "requires an argument\n";
      else
        std::cerr << "Unknown option" << optopt << "\n";
      return 1;
    default:
      abort();
    }

  if (stress_params_file == nullptr) {
    std::cerr << "Stress param file (-s) must be set\n";
    return 1;
  }

  if (test_params_file == nullptr) {
    std::cerr << "Test param file (-t) must be set\n";
    return 1;
  }

  StressParams stressParams;
  if (parseStressParamsFile(stress_params_file, &stressParams) != 0) {
    return 1;
  }

  TestParams testParams;
  if (parseTestParamsFile(test_params_file, &testParams) != 0) {
    return 1;
  }
  run(stressParams, testParams, print_results);
}
