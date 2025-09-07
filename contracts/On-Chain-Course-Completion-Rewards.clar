(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-enrolled (err u103))
(define-constant err-already-completed (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-invalid-milestone (err u106))
(define-constant err-course-not-active (err u107))

(define-constant badge-speed-demon u1)
(define-constant badge-perfectionist u2)
(define-constant badge-early-bird u3)
(define-constant badge-milestone-master u4)

(define-data-var next-certificate-id uint u1)

(define-constant err-cert-not-found (err u111))
(define-constant err-cert-already-exists (err u112))


(define-fungible-token learn-token)

(define-map courses
  { course-id: uint }
  {
    title: (string-ascii 100),
    instructor: principal,
    reward-amount: uint,
    milestone-count: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map enrollments
  { student: principal, course-id: uint }
  {
    enrolled-at: uint,
    completed-milestones: uint,
    is-completed: bool,
    completion-date: (optional uint)
  }
)

(define-map milestones
  { course-id: uint, milestone-id: uint }
  {
    title: (string-ascii 100),
    reward-amount: uint,
    is-active: bool
  }
)

(define-map student-milestones
  { student: principal, course-id: uint, milestone-id: uint }
  {
    completed-at: uint,
    reward-claimed: bool
  }
)

(define-data-var next-course-id uint u1)
(define-data-var total-rewards-distributed uint u0)

(define-read-only (get-course (course-id uint))
  (map-get? courses { course-id: course-id })
)

(define-read-only (get-enrollment (student principal) (course-id uint))
  (map-get? enrollments { student: student, course-id: course-id })
)

(define-read-only (get-milestone (course-id uint) (milestone-id uint))
  (map-get? milestones { course-id: course-id, milestone-id: milestone-id })
)

(define-read-only (get-student-milestone (student principal) (course-id uint) (milestone-id uint))
  (map-get? student-milestones { student: student, course-id: course-id, milestone-id: milestone-id })
)

(define-read-only (get-token-balance (account principal))
  (ft-get-balance learn-token account)
)

(define-read-only (get-total-supply)
  (ft-get-supply learn-token)
)

(define-read-only (get-total-rewards-distributed)
  (var-get total-rewards-distributed)
)

(define-read-only (is-student-enrolled (student principal) (course-id uint))
  (is-some (map-get? enrollments { student: student, course-id: course-id }))
)

(define-read-only (get-student-progress (student principal) (course-id uint))
  (match (map-get? enrollments { student: student, course-id: course-id })
    enrollment (some {
      completed-milestones: (get completed-milestones enrollment),
      is-completed: (get is-completed enrollment),
      completion-date: (get completion-date enrollment)
    })
    none
  )
)

(define-public (create-course (title (string-ascii 100)) (reward-amount uint) (milestone-count uint))
  (let ((course-id (var-get next-course-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set courses
      { course-id: course-id }
      {
        title: title,
        instructor: tx-sender,
        reward-amount: reward-amount,
        milestone-count: milestone-count,
        is-active: true,
        created-at: stacks-block-height
      }
    )
    (var-set next-course-id (+ course-id u1))
    (ok course-id)
  )
)

(define-public (add-milestone (course-id uint) (milestone-id uint) (title (string-ascii 100)) (reward-amount uint))
  (let ((course (unwrap! (map-get? courses { course-id: course-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get is-active course) err-course-not-active)
    (asserts! (is-none (map-get? milestones { course-id: course-id, milestone-id: milestone-id })) err-already-exists)
    (map-set milestones
      { course-id: course-id, milestone-id: milestone-id }
      {
        title: title,
        reward-amount: reward-amount,
        is-active: true
      }
    )
    (ok true)
  )
)

(define-public (enroll-student (course-id uint))
  (let ((course (unwrap! (map-get? courses { course-id: course-id }) err-not-found)))
    (asserts! (get is-active course) err-course-not-active)
    (asserts! (is-none (map-get? enrollments { student: tx-sender, course-id: course-id })) err-already-exists)
    (map-set enrollments
      { student: tx-sender, course-id: course-id }
      {
        enrolled-at: stacks-block-height,
        completed-milestones: u0,
        is-completed: false,
        completion-date: none
      }
    )
    (ok true)
  )
)

(define-public (complete-milestone (course-id uint) (milestone-id uint))
  (let (
    (course (unwrap! (map-get? courses { course-id: course-id }) err-not-found))
    (milestone (unwrap! (map-get? milestones { course-id: course-id, milestone-id: milestone-id }) err-invalid-milestone))
    (enrollment (unwrap! (map-get? enrollments { student: tx-sender, course-id: course-id }) err-not-enrolled))
  )
    (asserts! (get is-active course) err-course-not-active)
    (asserts! (get is-active milestone) err-invalid-milestone)
    (asserts! (is-none (map-get? student-milestones { student: tx-sender, course-id: course-id, milestone-id: milestone-id })) err-already-completed)
    
    (map-set student-milestones
      { student: tx-sender, course-id: course-id, milestone-id: milestone-id }
      {
        completed-at: stacks-block-height,
        reward-claimed: false
      }
    )
    
    (let ((new-completed-count (+ (get completed-milestones enrollment) u1)))
      (map-set enrollments
        { student: tx-sender, course-id: course-id }
        (merge enrollment { completed-milestones: new-completed-count })
      )
      
      (try! (ft-mint? learn-token (get reward-amount milestone) tx-sender))
      (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) (get reward-amount milestone)))
      
      (map-set student-milestones
        { student: tx-sender, course-id: course-id, milestone-id: milestone-id }
        {
          completed-at: stacks-block-height,
          reward-claimed: true
        }
      )
      
      (ok new-completed-count)
    )
  )
)

(define-public (complete-course (course-id uint))
  (let (
    (course (unwrap! (map-get? courses { course-id: course-id }) err-not-found))
    (enrollment (unwrap! (map-get? enrollments { student: tx-sender, course-id: course-id }) err-not-enrolled))
  )
    (asserts! (get is-active course) err-course-not-active)
    (asserts! (not (get is-completed enrollment)) err-already-completed)
    (asserts! (>= (get completed-milestones enrollment) (get milestone-count course)) err-invalid-milestone)
    
    (map-set enrollments
      { student: tx-sender, course-id: course-id }
      (merge enrollment {
        is-completed: true,
        completion-date: (some stacks-block-height)
      })
    )
    
    (try! (ft-mint? learn-token (get reward-amount course) tx-sender))
    (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) (get reward-amount course)))
    
    (ok true)
  )
)

(define-public (transfer-tokens (amount uint) (recipient principal))
  (ft-transfer? learn-token amount tx-sender recipient)
)

(define-public (toggle-course-status (course-id uint))
  (let ((course (unwrap! (map-get? courses { course-id: course-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set courses
      { course-id: course-id }
      (merge course { is-active: (not (get is-active course)) })
    )
    (ok (not (get is-active course)))
  )
)

(define-public (mint-tokens-to-contract (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ft-mint? learn-token amount contract-owner)
  )
)


;; Badge definitions
(define-map badges
  { badge-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    is-active: bool
  }
)

;; Student badges
(define-map student-badges
  { student: principal, badge-id: uint }
  {
    earned-at: uint,
    course-id: (optional uint)
  }
)

;; Course enrollment tracking for early bird badge
(define-map course-enrollment-count
  { course-id: uint }
  { count: uint }
)

;; Initialize badges
(map-set badges { badge-id: badge-speed-demon }
  { name: "Speed Demon", description: "Complete a course in under 30 days", is-active: true })
(map-set badges { badge-id: badge-perfectionist }
  { name: "Perfectionist", description: "Complete all milestones before finishing course", is-active: true })
(map-set badges { badge-id: badge-early-bird }
  { name: "Early Bird", description: "Be among first 10 students to enroll in a course", is-active: true })
(map-set badges { badge-id: badge-milestone-master }
  { name: "Milestone Master", description: "Complete 5 milestones across any courses", is-active: true })

;; Read-only functions
(define-read-only (get-badge (badge-id uint))
  (map-get? badges { badge-id: badge-id })
)

(define-read-only (get-student-badge (student principal) (badge-id uint))
  (map-get? student-badges { student: student, badge-id: badge-id })
)

(define-read-only (has-badge (student principal) (badge-id uint))
  (is-some (map-get? student-badges { student: student, badge-id: badge-id }))
)

(define-read-only (get-student-badge-count (student principal))
  (+ (if (has-badge student badge-speed-demon) u1 u0)
     (if (has-badge student badge-perfectionist) u1 u0)
     (if (has-badge student badge-early-bird) u1 u0)
     (if (has-badge student badge-milestone-master) u1 u0))
)

;; Private functions
(define-private (award-badge (student principal) (badge-id uint) (course-id (optional uint)))
  (begin
    (map-set student-badges
      { student: student, badge-id: badge-id }
      { earned-at: stacks-block-height, course-id: course-id })
    true
  )
)

(define-private (check-milestone-master (student principal))
  (let ((milestone-count (get-student-total-milestones student)))
    (if (and (>= milestone-count u5) (not (has-badge student badge-milestone-master)))
      (award-badge student badge-milestone-master none)
      true
    )
  )
)

(define-private (get-student-total-milestones (student principal))
  u0
)

;; Public functions to integrate with existing enrollment/completion
(define-public (enroll-with-badge-check (course-id uint))
  (let ((enrollment-count (default-to u0 (get count (map-get? course-enrollment-count { course-id: course-id })))))
    (if (< enrollment-count u10)
      (begin
        (map-set course-enrollment-count { course-id: course-id } { count: (+ enrollment-count u1) })
        (award-badge tx-sender badge-early-bird (some course-id))
      )
      (map-set course-enrollment-count { course-id: course-id } { count: (+ enrollment-count u1) })
    )
    (ok true)
  )
)

(define-public (complete-course-with-badge-check (course-id uint))
  (let (
    (course (unwrap! (map-get? courses { course-id: course-id }) err-not-found))
    (enrollment (unwrap! (map-get? enrollments { student: tx-sender, course-id: course-id }) err-not-enrolled))
  )
    (let ((completion-time (- stacks-block-height (get enrolled-at enrollment))))
      (if (< completion-time u4320)
        (award-badge tx-sender badge-speed-demon (some course-id))
        true
      )
      (if (is-eq (get completed-milestones enrollment) (get milestone-count course))
        (award-badge tx-sender badge-perfectionist (some course-id))
        true
      )
      (check-milestone-master tx-sender)
      (ok true)
    )
  )
)

(define-map course-reviews
  { course-id: uint, student: principal }
  {
    rating: uint,
    review-text: (string-ascii 500),
    submitted-at: uint
  }
)

(define-map course-rating-summary
  { course-id: uint }
  {
    total-ratings: uint,
    rating-sum: uint,
    review-count: uint
  }
)

(define-constant err-not-completed (err u108))
(define-constant err-already-reviewed (err u109))
(define-constant err-invalid-rating (err u110))

(define-read-only (get-course-review (course-id uint) (student principal))
  (map-get? course-reviews { course-id: course-id, student: student })
)

(define-read-only (get-course-rating-summary (course-id uint))
  (map-get? course-rating-summary { course-id: course-id })
)

(define-read-only (get-course-average-rating (course-id uint))
  (match (map-get? course-rating-summary { course-id: course-id })
    summary (if (> (get total-ratings summary) u0)
              (some (/ (get rating-sum summary) (get total-ratings summary)))
              none)
    none
  )
)

(define-read-only (has-reviewed-course (course-id uint) (student principal))
  (is-some (map-get? course-reviews { course-id: course-id, student: student }))
)

(define-public (submit-course-review (course-id uint) (rating uint) (review-text (string-ascii 500)))
  (let (
    (enrollment (unwrap! (map-get? enrollments { student: tx-sender, course-id: course-id }) err-not-enrolled))
    (current-summary (default-to { total-ratings: u0, rating-sum: u0, review-count: u0 } 
                     (map-get? course-rating-summary { course-id: course-id })))
  )
    (asserts! (get is-completed enrollment) err-not-completed)
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    (asserts! (is-none (map-get? course-reviews { course-id: course-id, student: tx-sender })) err-already-reviewed)
    
    (map-set course-reviews
      { course-id: course-id, student: tx-sender }
      {
        rating: rating,
        review-text: review-text,
        submitted-at: stacks-block-height
      }
    )
    
    (map-set course-rating-summary
      { course-id: course-id }
      {
        total-ratings: (+ (get total-ratings current-summary) u1),
        rating-sum: (+ (get rating-sum current-summary) rating),
        review-count: (+ (get review-count current-summary) u1)
      }
    )
    
    (ok true)
  )
)

(define-non-fungible-token course-certificate uint)

(define-map certificates
  { certificate-id: uint }
  {
    student: principal,
    course-id: uint,
    course-title: (string-ascii 100),
    issued-at: uint,
    completion-time-days: uint,
    final-grade: uint
  }
)


(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates { certificate-id: certificate-id })
)

(define-read-only (get-student-certificate-count (student principal))
  (let ((count u0))
    (+ (if (is-eq (nft-get-owner? course-certificate u1) (some student)) u1 u0)
       (if (is-eq (nft-get-owner? course-certificate u2) (some student)) u1 u0)
       (if (is-eq (nft-get-owner? course-certificate u3) (some student)) u1 u0))
  )
)

(define-read-only (certificate-exists (certificate-id uint))
  (is-some (nft-get-owner? course-certificate certificate-id))
)

(define-public (mint-course-certificate (course-id uint))
  (let (
    (course (unwrap! (map-get? courses { course-id: course-id }) err-not-found))
    (enrollment (unwrap! (map-get? enrollments { student: tx-sender, course-id: course-id }) err-not-enrolled))
    (certificate-id (var-get next-certificate-id))
    (completion-days (/ (- stacks-block-height (get enrolled-at enrollment)) u144))
    (grade (if (<= (+ u70 (* (get completed-milestones enrollment) u5)) u100)
               (+ u70 (* (get completed-milestones enrollment) u5))
               u100))
  )
    (asserts! (get is-completed enrollment) err-not-completed)
    (asserts! (is-none (nft-get-owner? course-certificate certificate-id)) err-cert-already-exists)
    
    (try! (nft-mint? course-certificate certificate-id tx-sender))
    
    (map-set certificates
      { certificate-id: certificate-id }
      {
        student: tx-sender,
        course-id: course-id,
        course-title: (get title course),
        issued-at: stacks-block-height,
        completion-time-days: completion-days,
        final-grade: grade
      }
    )
    
    (var-set next-certificate-id (+ certificate-id u1))
    (ok certificate-id)
  )
)

(define-public (transfer-certificate (certificate-id uint) (recipient principal))
  (nft-transfer? course-certificate certificate-id tx-sender recipient)
)