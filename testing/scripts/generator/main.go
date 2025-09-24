// visualize_epsilon_empirical.go
//
// Build:
//   go build -O -o visualize_epsilon_empirical visualize_epsilon_empirical.go
//
// Run:
//   ./visualize_epsilon_empirical -start=0 -end=10 -steps=100 -trials=100000 -maxk=20 -out=out -seed=12345
//
// NOTE: Provide your implementations of RandomBoolean and PoissonSample in the same package
// (either in this file by uncommenting the stubs or in another .go file in the same module).

package main

import (
	"bufio"
	"encoding/csv"
	"flag"
	"fmt"
	"log"
	"math"
	"math/rand"
	"os"
	"strconv"
	"time"
)

/* ------------------- USER-PROVIDED FUNCTIONS -------------------
   Provide these in this package when compiling. Replace the stubs below
   with your implemented versions (or put implementations in another .go file).
*/

const (
	lower = 1
	upper = 10
	target = 2
)

func clamp(v, lo, hi float64) float64 {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}

// RandomBoolean should return 0 or 1 based on epsilon.
func RandomBoolean(epsilon float64) int {
	if epsilon < 0.0 {
		return 1
	}
	p := math.Exp(epsilon) / (math.Exp(epsilon) + 1.0)
	if rand.Float64() < p {
		return 1
	}
	return 0
}

// PoissonSample should return an integer >= 0 based on epsilon.
// STUB: Knuth's algorithm (fine for small lambda). Replace with your implementation.
func PoissonSample(epsilon float64) int {
	lambda := float64(upper - lower) / epsilon
	p := math.Exp(-lambda)
	sum := p
	k := 0
	for rand.Float64() >= sum {
		k++
		p *= lambda / float64(k)
		sum += p
	}
	return int(float64(k)+float64(lower))
}

/* ---------------------------------------------------------------- */

func main() {
	// Command-line flags
	start := flag.Float64("start", 0.0, "start epsilon")
	end := flag.Float64("end", 10.0, "end epsilon")
	steps := flag.Int("steps", 100, "number of steps (program iterates i = 0..steps inclusive)")
	trials := flag.Int64("trials", 100000, "trials per epsilon")
	maxK := flag.Int("maxk", 20, "Poisson buckets 0..maxk, overflow as >=maxk+1")
	outPrefix := flag.String("out", "out", "output filename prefix")
	seed := flag.Int64("seed", time.Now().UnixNano(), "random seed (int64)")
	flag.Parse()

	if *steps < 0 {
		log.Fatalf("steps must be >= 0")
	}
	if *trials <= 0 {
		log.Fatalf("trials must be > 0")
	}
	if *maxK < 0 {
		log.Fatalf("maxk must be >= 0")
	}

	rand.Seed(*seed)
	log.Printf("visualize_epsilon_empirical: start=%v end=%v steps=%d trials=%d max_k=%d prefix=%s seed=%d",
		*start, *end, *steps, *trials, *maxK, *outPrefix, *seed)

	// Open CSV files
	boolF, err := os.Create(fmt.Sprintf("%s_boolean.csv", *outPrefix))
	if err != nil {
		log.Fatalf("failed to create boolean CSV: %v", err)
	}
	defer boolF.Close()
	poisF, err := os.Create(fmt.Sprintf("%s_poisson.csv", *outPrefix))
	if err != nil {
		log.Fatalf("failed to create poisson CSV: %v", err)
	}
	defer poisF.Close()
	psumF, err := os.Create(fmt.Sprintf("%s_poisson_summary.csv", *outPrefix))
	if err != nil {
		log.Fatalf("failed to create poisson summary CSV: %v", err)
	}
	defer psumF.Close()

	boolW := csv.NewWriter(bufio.NewWriter(boolF))
	poisW := csv.NewWriter(bufio.NewWriter(poisF))
	psumW := csv.NewWriter(bufio.NewWriter(psumF))

	// Write headers
	if err := boolW.Write([]string{"epsilon", "empirical_prob_true", "count_true", "trials"}); err != nil {
		log.Fatalf("write header boolean: %v", err)
	}
	if err := poisW.Write([]string{"epsilon", "k", "empirical_prob", "count"}); err != nil {
		log.Fatalf("write header poisson: %v", err)
	}
	if err := psumW.Write([]string{"epsilon", "empirical_mean", "empirical_variance", "overflow_count", "trials"}); err != nil {
		log.Fatalf("write header poisson_summary: %v", err)
	}

	// Sanity sample prints (first 20 calls for eps=start and eps=end)
	log.Printf("Sanity samples (first 20) at eps=start=%g and eps=end=%g", *start, *end)
	for si, eps := range []float64{*start, *end} {
		for t := 0; t < 20; t++ {
			b := RandomBoolean(eps)
			k := PoissonSample(eps)
			if k < 0 {
				log.Fatalf("PoissonSample returned invalid value %d at eps=%g (sanity test index %d)", k, eps, t)
			}
			if si == 0 && t < 5 {
				// only print a few to keep logs sane
				log.Printf("eps=%.6g trial=%2d -> bool=%d, pois=%d", eps, t, b, k)
			} else if si == 1 && t < 5 {
				log.Printf("eps=%.6g trial=%2d -> bool=%d, pois=%d", eps, t, b, k)
			}
		}
	}

	// Sweep
	t0 := time.Now()
	stepsFloat := float64(*steps)
	for i := 0; i <= *steps; i++ {
		var eps float64
		if *steps == 0 {
			eps = *start
		} else {
			eps = *start + (*end-*start)*float64(i)/stepsFloat
		}

		var countTrue int64 = 0
		buckets := *maxK + 2 // 0..maxK and overflow at index maxK+1
		hist := make([]int64, buckets)

		// run trials
		startLoop := time.Now()
		for t := int64(0); t < *trials; t++ {
			b := RandomBoolean(eps)
			if b != 0 {
				countTrue++
			}
			k := PoissonSample(eps)
			if k < 0 {
				log.Fatalf("PoissonSample returned invalid value %d at eps=%g during main sweep (i=%d)", k, eps, i)
			}
			if k <= *maxK {
				hist[k]++
			} else {
				hist[*maxK+1]++
			}
		}
		loopDur := time.Since(startLoop)

		// boolean CSV row
		empP := float64(countTrue) / float64(*trials)
		if err := boolW.Write([]string{
			formatFloat(eps), formatFloat(empP), strconv.FormatInt(countTrue, 10), strconv.FormatInt(*trials, 10),
		}); err != nil {
			log.Fatalf("write boolean row: %v", err)
		}

		// poisson CSV rows for k=0..maxK
		for k := 0; k <= *maxK; k++ {
			cnt := hist[k]
			empProb := float64(cnt) / float64(*trials)
			if err := poisW.Write([]string{
				formatFloat(eps), strconv.Itoa(k), formatFloat(empProb), strconv.FormatInt(cnt, 10),
			}); err != nil {
				log.Fatalf("write poisson row: %v", err)
			}
		}
		// overflow row
		overflowCnt := hist[*maxK+1]
		overflowProb := float64(overflowCnt) / float64(*trials)
		if err := poisW.Write([]string{
			formatFloat(eps), ">=" + strconv.Itoa(*maxK+1), formatFloat(overflowProb), strconv.FormatInt(overflowCnt, 10),
		}); err != nil {
			log.Fatalf("write poisson overflow row: %v", err)
		}

		// mean & variance (approx: overflow counted as value maxK+1)
		var mean float64 = 0.0
		var ex2 float64 = 0.0
		for k := 0; k <= *maxK; k++ {
			v := float64(k)
			cnt := float64(hist[k])
			if cnt > 0 {
				mean += v * cnt
				ex2 += v * v * cnt
			}
		}
		overflowValue := float64(*maxK + 1)
		mean += overflowValue * float64(overflowCnt)
		ex2 += overflowValue * overflowValue * float64(overflowCnt)
		mean /= float64(*trials)
		ex2 /= float64(*trials)
		variance := ex2 - mean*mean
		if variance < 0 && variance > -1e-12 {
			variance = 0
		}

		if err := psumW.Write([]string{
			formatFloat(eps), formatFloat(mean), formatFloat(variance), strconv.FormatInt(overflowCnt, 10), strconv.FormatInt(*trials, 10),
		}); err != nil {
			log.Fatalf("write poisson summary row: %v", err)
		}

		// flush periodically to ensure outputs exist on disk
		if i%50 == 0 {
			boolW.Flush()
			poisW.Flush()
			psumW.Flush()
		}

		// progress print
		if i%(max(1, *steps/20)) == 0 {
			log.Printf("eps=%.6g  P(true)=%.6g  mean≈%.6g  var≈%.6g  overflow=%d  (trials=%d, loop dur=%s)",
				eps, empP, mean, variance, overflowCnt, *trials, loopDur.Truncate(time.Millisecond))
		}
	}
	// final flush
	boolW.Flush()
	poisW.Flush()
	psumW.Flush()

	log.Printf("Done in %s. Outputs:\n - %s_boolean.csv\n - %s_poisson.csv\n - %s_poisson_summary.csv",
		time.Since(t0).Truncate(time.Millisecond), *outPrefix, *outPrefix, *outPrefix)
}

// formatFloat prints float with sufficient precision for CSV
func formatFloat(v float64) string {
	// use 12 significant digits similar to the C code
	return strconv.FormatFloat(v, 'g', 12, 64)
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
