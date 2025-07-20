;; Intellectual Property Rights Management
;; Enables creators to register, manage, and monetize intellectual property rights
;; with transparent licensing, royalty distribution, and usage tracking

;; Define NFT trait locally instead of importing from an external contract
(define-trait digital-asset-trait
  (
    ;; Last token ID, limited to uint range
    (get-last-token-id () (response uint uint))
    ;; URI for metadata associated with the token
    (get-token-uri (uint) (response (optional (string-utf8 256)) uint))
    ;; Owner of a specific token
    (get-owner (uint) (response (optional principal) uint))
    ;; Transfer token to a new principal
    (transfer (uint principal principal) (response bool uint))
  )
)

;; Intellectual property registrations
(define-map creative-registrations
  { record-id: uint }
  {
    work-title: (string-utf8 256),
    work-description: (string-utf8 1024),
    originator: principal,
    established-at: uint,
    creative-type: (string-ascii 32),     ;; "image", "music", "text", "code", "video", "design", etc.
    material-hash: (buff 64),        ;; Hash of the IP content
    record-status: (string-ascii 16),      ;; "registered", "disputed", "revoked"
    token-contract: (optional principal),  ;; Optional NFT contract for this IP
    token-id: (optional uint),        ;; Optional NFT ID within the contract
    open-domain: bool,            ;; Whether the work is in the public domain
    record-expiry: (optional uint)  ;; Optional block height when registration expires
  }
)

;; IP ownership shares (can be fractional)
(define-map creative-ownership
  { record-id: uint, holder: principal }
  {
    ownership-percentage: uint,         ;; Out of 10000 (e.g., 5000 = 50%)
    obtained-at: uint,
    obtained-from: (optional principal)
  }
)

;; License templates
(define-map agreement-templates
  { template-id: uint }
  {
    template-name: (string-utf8 64),
    template-description: (string-utf8 1024),
    template-creator: principal,
    template-created-at: uint,
    permitted-rights: (list 10 (string-ascii 32)),  ;; e.g., "reproduce", "distribute", "derivative", "commercial"
    payment-fee-type: (string-ascii 16),        ;; "one-time", "recurring", "usage-based", "free"
    standard-fee: uint,                          ;; Default fee amount
    standard-duration: (optional uint),          ;; Default duration in blocks
    assignable: bool,                         ;; Whether license can be transferred
    exclusive-available: bool,                ;; Whether exclusive licenses are available
    region-restricted: bool,                 ;; Whether license can be territory-restricted
    agreement-uri: (string-utf8 256)             ;; URI to the full legal template
  }
)

;; Granted licenses
(define-map issued-licenses
  { agreement-id: uint }
  {
    record-id: uint,          ;; The IP being licensed
    template-id: uint,              ;; The license template used
    grantor: principal,            ;; Entity granting the license
    grantee: principal,            ;; Entity receiving the license
    issued-at: uint,
    terminates-at: (optional uint),
    payment-paid: uint,
    region: (optional (string-ascii 64)),
    sole: bool,
    operational: bool,
    utilization-counter: uint,            ;; Counter for usage-based licensing
    max-utilization: (optional uint),     ;; Max allowed usage
    special-terms: (optional (string-utf8 1024)),
    cancelled: bool,
    cancellation-reason: (optional (string-utf8 256))
  }
)

;; Usage logs for IP
(define-map creative-utilization-logs
  { record-id: uint, utilization-id: uint }
  {
    grantee: principal,
    agreement-id: (optional uint),
    utilization-type: (string-ascii 32),
    service-platform: (string-ascii 64),
    utilization-hash: (buff 32),          ;; Hash of usage evidence
    log-timestamp: uint,
    income-generated: (optional uint),
    validated: bool,
    validator: (optional principal)
  }
)

;; Royalty recipients
(define-map payment-recipients
  { record-id: uint, beneficiary: principal }
  {
    beneficiary-percentage: uint,         ;; Out of 10000
    beneficiary-type: (string-ascii 16),  ;; "creator", "collaborator", "label", "publisher", etc.
    beneficiary-active: bool
  }
)

;; Royalty payments
(define-map compensation-payments
  { transaction-id: uint }
  {
    record-id: uint,
    agreement-id: (optional uint),
    contributor: principal,
    transaction-amount: uint,
    transaction-timestamp: uint,
    utilization-id: (optional uint),
    transaction-type: (string-ascii 16),  ;; "license-fee", "royalty", "settlement"
    allocated: bool
  }
)

;; Dispute records
(define-map creative-disputes
  { dispute-id: uint }
  {
    record-id: uint,
    complainant: principal,
    submitted-at: uint,
    complaint-basis: (string-utf8 256),
    proof-hash: (buff 32),
    dispute-status: (string-ascii 16),      ;; "pending", "resolved", "rejected", "withdrawn"
    outcome: (optional (string-utf8 256)),
    arbitrator: (optional principal),
    concluded-at: (optional uint)
  }
)

;; Derivative works
(define-map derived-works
  { source-id: uint, derived-id: uint }
  {
    connection-type: (string-ascii 32),  ;; "adaptation", "translation", "remix", etc.
    authorized: bool,
    authorization-date: (optional uint),
    compensation-percentage: uint        ;; How much goes back to original work
  }
)

;; Next available IDs
(define-data-var next-record-id uint u0)
(define-data-var next-template-id uint u0)
(define-data-var next-agreement-id uint u0)
(define-data-var next-dispute-id uint u0)
(define-data-var next-transaction-id uint u0)
(define-map next-utilization-id { record-id: uint } { id: uint })

;; Protocol configuration
(define-data-var arbitration-address principal tx-sender)
(define-data-var system-fee-percentage uint u250)  ;; 2.5% of transactions
(define-data-var dispute-submission-fee uint u1000000)   ;; 1 STX

;; Validation functions
(define-private (validate-record-id (record-id uint))
  (if (< record-id (var-get next-record-id))
      (ok record-id)
      (err u"Invalid registration ID"))
)

(define-private (validate-utf8-256 (text (string-utf8 256)))
  (if (> (len text) u0)
      (ok text)
      (err u"Text cannot be empty"))
)

(define-private (validate-utf8-64 (text (string-utf8 64)))
  (if (> (len text) u0)
      (ok text)
      (err u"Text cannot be empty"))
)

(define-private (validate-utf8-1024 (text (string-utf8 1024)))
  (if (> (len text) u0)
      (ok text)
      (err u"Text cannot be empty"))
)

(define-private (validate-material-hash (material-hash (buff 64)))
  (if (> (len material-hash) u0)
      (ok material-hash)
      (err u"Content hash cannot be empty"))
)

(define-private (validate-template-id (template-id uint))
  (if (< template-id (var-get next-template-id))
      (ok template-id)
      (err u"Invalid template ID"))
)

(define-private (validate-agreement-id (agreement-id uint))
  (if (< agreement-id (var-get next-agreement-id))
      (ok agreement-id)
      (err u"Invalid license ID"))
)

(define-private (validate-dispute-id (dispute-id uint))
  (if (< dispute-id (var-get next-dispute-id))
      (ok dispute-id)
      (err u"Invalid dispute ID"))
)

(define-private (validate-utilization-id (record-id uint) (utilization-id uint))
  (match (map-get? next-utilization-id { record-id: record-id })
    counter (if (< utilization-id (get id counter))
               (ok utilization-id)
               (err u"Invalid usage ID"))
    (err u"Registration ID not found"))
)

(define-private (validate-connection-type (connection-type (string-ascii 32)))
  (if (or (is-eq connection-type "adaptation")
          (or (is-eq connection-type "translation")
              (or (is-eq connection-type "remix")
                  (is-eq connection-type "derivative"))))
      (ok connection-type)
      (err u"Invalid relationship type"))
)

(define-private (validate-utilization-type (utilization-type (string-ascii 32)))
  (if (or (is-eq utilization-type "online-display")
          (or (is-eq utilization-type "broadcast")
              (or (is-eq utilization-type "print")
                  (or (is-eq utilization-type "merchandise")
                      (is-eq utilization-type "performance")))))
      (ok utilization-type)
      (err u"Invalid usage type"))
)

(define-private (validate-beneficiary-type (beneficiary-type (string-ascii 16)))
  (if (or (is-eq beneficiary-type "creator")
          (or (is-eq beneficiary-type "collaborator")
              (or (is-eq beneficiary-type "label")
                  (or (is-eq beneficiary-type "publisher")
                      (is-eq beneficiary-type "distributor")))))
      (ok beneficiary-type)
      (err u"Invalid recipient type"))
)

(define-private (validate-transaction-type (transaction-type (string-ascii 16)))
  (if (or (is-eq transaction-type "license-fee")
          (or (is-eq transaction-type "royalty")
              (is-eq transaction-type "settlement")))
      (ok transaction-type)
      (err u"Invalid payment type"))
)

;; Register new intellectual property
(define-public (register-creative-work
                (work-title (string-utf8 256))
                (work-description (string-utf8 1024))
                (creative-type (string-ascii 32))
                (material-hash (buff 64))
                (open-domain bool)
                (record-expiry (optional uint)))
  (let
    ((validated-title-resp (validate-utf8-256 work-title))
     (validated-description-resp (validate-utf8-1024 work-description))
     (validated-hash-resp (validate-material-hash material-hash))
     (record-id (var-get next-record-id)))
    
    ;; Validate parameters
    (asserts! (is-valid-creative-type creative-type) (err u"Invalid IP type"))
    (asserts! (is-ok validated-title-resp) (err (unwrap-err! validated-title-resp (err u"Title validation failed"))))
    (asserts! (is-ok validated-description-resp) (err (unwrap-err! validated-description-resp (err u"Description validation failed"))))
    (asserts! (is-ok validated-hash-resp) (err (unwrap-err! validated-hash-resp (err u"Content hash validation failed"))))
    
    ;; Create the registration
    (map-set creative-registrations
      { record-id: record-id }
      {
        work-title: (unwrap-panic validated-title-resp),
        work-description: (unwrap-panic validated-description-resp),
        originator: tx-sender,
        established-at: block-height,
        creative-type: creative-type,
        material-hash: (unwrap-panic validated-hash-resp),
        record-status: "registered",
        token-contract: none,
        token-id: none,
        open-domain: open-domain,
        record-expiry: record-expiry
      }
    )
    
    ;; Set initial ownership
    (map-set creative-ownership
      { record-id: record-id, holder: tx-sender }
      {
        ownership-percentage: u10000,     ;; 100%
        obtained-at: block-height,
        obtained-from: none
      }
    )
    
    ;; Initialize usage counter
    (map-set next-utilization-id
      { record-id: record-id }
      { id: u0 }
    )
    
    ;; Increment registration ID counter
    (var-set next-record-id (+ record-id u1))
    
    (ok record-id)
  )
)

;; Check if IP type is valid
(define-private (is-valid-creative-type (creative-type (string-ascii 32)))
  (or (is-eq creative-type "image")
      (or (is-eq creative-type "music")
          (or (is-eq creative-type "text")
              (or (is-eq creative-type "code")
                  (or (is-eq creative-type "video")
                      (is-eq creative-type "design"))))))
)

;; Link an NFT to an IP registration
(define-public (link-token-to-creative-work
                (record-id uint)
                (token-contract principal)
                (token-id uint))
  (let
    ((validated-id-resp (validate-record-id record-id)))
    
    ;; Validate registration ID is valid
    (asserts! (is-ok validated-id-resp)
              (err (unwrap-err! validated-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-id (unwrap-panic validated-id-resp)))
      ;; Get the registration
      (let ((registration (unwrap! (map-get? creative-registrations { record-id: validated-id })
                                   (err u"Registration not found"))))
        ;; Validate
        (asserts! (is-eq tx-sender (get originator registration))
                  (err u"Only creator can link NFT"))
        (asserts! (is-eq (get record-status registration) "registered")
                  (err u"Registration not in valid state"))
        
        ;; TODO: In a real implementation, verify NFT ownership
        ;; Update registration with NFT info
        (map-set creative-registrations
          { record-id: validated-id }
          (merge registration
            {
              token-contract: (some token-contract),
              token-id: (some token-id)
            }
          )
        )
        
        (ok true)
      )
    )
  )
)

;; Create a license template
(define-public (create-agreement-template
                (template-name (string-utf8 64))
                (template-description (string-utf8 1024))
                (permitted-rights (list 10 (string-ascii 32)))
                (payment-fee-type (string-ascii 16))
                (standard-fee uint)
                (standard-duration (optional uint))
                (assignable bool)
                (exclusive-available bool)
                (region-restricted bool)
                (agreement-uri (string-utf8 256)))
  (let
    ((validated-name-resp (validate-utf8-64 template-name))
     (validated-description-resp (validate-utf8-1024 template-description))
     (template-id (var-get next-template-id)))
    
    ;; Validate parameters
    (asserts! (is-ok validated-name-resp)
              (err (unwrap-err! validated-name-resp (err u"Name validation failed"))))
    (asserts! (is-ok validated-description-resp)
              (err (unwrap-err! validated-description-resp (err u"Description validation failed"))))
    (asserts! (is-valid-payment-type payment-fee-type) (err u"Invalid fee type"))
    (asserts! (> (len permitted-rights) u0) (err u"Must provide at least one usage right"))
    
    (let
      ((validated-name (unwrap-panic validated-name-resp))
       (validated-description (unwrap-panic validated-description-resp)))
      
      ;; Create the template
      (map-set agreement-templates
        { template-id: template-id }
        {
          template-name: validated-name,
          template-description: validated-description,
          template-creator: tx-sender,
          template-created-at: block-height,
          permitted-rights: permitted-rights,
          payment-fee-type: payment-fee-type,
          standard-fee: standard-fee,
          standard-duration: standard-duration,
          assignable: assignable,
          exclusive-available: exclusive-available,
          region-restricted: region-restricted,
          agreement-uri: agreement-uri
        }
      )
      
      ;; Increment template ID counter
      (var-set next-template-id (+ template-id u1))
      
      (ok template-id)
    )
  )
)

;; Check if fee type is valid
(define-private (is-valid-payment-type (payment-type (string-ascii 16)))
  (or (is-eq payment-type "one-time")
      (or (is-eq payment-type "recurring")
          (or (is-eq payment-type "usage-based")
              (is-eq payment-type "free"))))
)

;; Grant a license to use IP - split into free and paid versions
;; This version is for free licenses (fee = 0)
(define-public (grant-free-agreement
                (record-id uint)
                (template-id uint)
                (grantee principal)
                (duration (optional uint))
                (region (optional (string-ascii 64)))
                (sole bool)
                (max-utilization (optional uint))
                (special-terms (optional (string-utf8 1024))))
  (let
    ((validated-record-id-resp (validate-record-id record-id))
     (validated-template-id-resp (validate-template-id template-id)))
    
    ;; Check validation results
    (asserts! (is-ok validated-record-id-resp)
              (err (unwrap-err! validated-record-id-resp (err u"Invalid registration ID"))))
    (asserts! (is-ok validated-template-id-resp)
              (err (unwrap-err! validated-template-id-resp (err u"Invalid template ID"))))
    
    (let ((validated-record-id (unwrap-panic validated-record-id-resp))
          (validated-template-id (unwrap-panic validated-template-id-resp)))
      
      ;; Get registration and template records
      (let ((registration (unwrap! (map-get? creative-registrations { record-id: validated-record-id })
                                  (err u"Registration not found")))
            (template (unwrap! (map-get? agreement-templates { template-id: validated-template-id })
                              (err u"Template not found")))
            (ownership (unwrap! (map-get? creative-ownership
                                { record-id: validated-record-id, holder: tx-sender })
                              (err u"Not an owner of this IP")))
            (agreement-id (var-get next-agreement-id)))
        
        ;; Validate
        (asserts! (is-eq (get record-status registration) "registered")
                  (err u"Registration not in valid state"))
        (asserts! (not (get open-domain registration))
                  (err u"Public domain works don't require licenses"))
        (asserts! (or (not sole) (get exclusive-available template))
                  (err u"Exclusive license not available for this template"))
        (asserts! (or (is-none region) (get region-restricted template))
                  (err u"Territory restrictions not available for this template"))
        
        ;; Calculate expiration if duration provided
        (let ((expiry (if (is-some duration)
                          (some (+ block-height (unwrap-panic duration)))
                          (get standard-duration template))))
          
          ;; Create the license grant
          (map-set issued-licenses
            { agreement-id: agreement-id }
            {
              record-id: validated-record-id,
              template-id: validated-template-id,
              grantor: tx-sender,
              grantee: grantee,
              issued-at: block-height,
              terminates-at: expiry,
              payment-paid: u0,  ;; Free license
              region: region,
              sole: sole,
              operational: true,
              utilization-counter: u0,
              max-utilization: max-utilization,
              special-terms: special-terms,
              cancelled: false,
              cancellation-reason: none
            }
          )
          
          ;; Increment license ID counter
          (var-set next-agreement-id (+ agreement-id u1))
          
          (ok agreement-id)
        )
      )
    )
  )
)

;; Grant a license with payment
(define-public (grant-paid-agreement
                (record-id uint)
                (template-id uint)
                (grantee principal)
                (payment uint)  ;; Must be > 0
                (duration (optional uint))
                (region (optional (string-ascii 64)))
                (sole bool)
                (max-utilization (optional uint))
                (special-terms (optional (string-utf8 1024))))
  (let
    ((validated-record-id-resp (validate-record-id record-id))
     (validated-template-id-resp (validate-template-id template-id)))
    
    ;; Check validation results
    (asserts! (is-ok validated-record-id-resp)
              (err (unwrap-err! validated-record-id-resp (err u"Invalid registration ID"))))
    (asserts! (is-ok validated-template-id-resp)
              (err (unwrap-err! validated-template-id-resp (err u"Invalid template ID"))))
    
    (let ((validated-record-id (unwrap-panic validated-record-id-resp))
          (validated-template-id (unwrap-panic validated-template-id-resp)))
      
      ;; Get registration and template records
      (let ((registration (unwrap! (map-get? creative-registrations { record-id: validated-record-id })
                                  (err u"Registration not found")))
            (template (unwrap! (map-get? agreement-templates { template-id: validated-template-id })
                              (err u"Template not found")))
            (ownership (unwrap! (map-get? creative-ownership
                                { record-id: validated-record-id, holder: tx-sender })
                              (err u"Not an owner of this IP")))
            (agreement-id (var-get next-agreement-id))
            (system-fee (/ (* payment (var-get system-fee-percentage)) u10000)))
        
        ;; Validate
        (asserts! (is-eq (get record-status registration) "registered")
                  (err u"Registration not in valid state"))
        (asserts! (not (get open-domain registration))
                  (err u"Public domain works don't require licenses"))
        (asserts! (or (not sole) (get exclusive-available template))
                  (err u"Exclusive license not available for this template"))
        (asserts! (or (is-none region) (get region-restricted template))
                  (err u"Territory restrictions not available for this template"))
        (asserts! (> payment u0) (err u"Fee must be greater than 0"))
        
        ;; Transfer fee from licensee
        (asserts! (is-ok (stx-transfer? payment grantee (as-contract tx-sender)))
                  (err u"License fee transfer failed"))
        
        ;; Transfer protocol fee
        (asserts! (is-ok (as-contract (stx-transfer? system-fee tx-sender (var-get arbitration-address))))
                 (err u"Protocol fee transfer failed"))
        
        ;; Calculate expiration if duration provided
        (let ((expiry (if (is-some duration)
                          (some (+ block-height (unwrap-panic duration)))
                          (get standard-duration template))))
          
          ;; Create the license grant
          (map-set issued-licenses
            { agreement-id: agreement-id }
            {
              record-id: validated-record-id,
              template-id: validated-template-id,
              grantor: tx-sender,
              grantee: grantee,
              issued-at: block-height,
              terminates-at: expiry,
              payment-paid: payment,
              region: region,
              sole: sole,
              operational: true,
              utilization-counter: u0,
              max-utilization: max-utilization,
              special-terms: special-terms,
              cancelled: false,
              cancellation-reason: none
            }
          )
          
          ;; Record payment
          (let ((transaction-id (var-get next-transaction-id)))
            ;; Create payment record
            (map-set compensation-payments
              { transaction-id: transaction-id }
              {
                record-id: validated-record-id,
                agreement-id: (some agreement-id),
                contributor: grantee,
                transaction-amount: payment,
                transaction-timestamp: block-height,
                utilization-id: none,
                transaction-type: "license-fee",
                allocated: true  ;; Simplified for this example
              }
            )
            
            ;; Increment payment ID counter
            (var-set next-transaction-id (+ transaction-id u1))
          )
          
          ;; Increment license ID counter
          (var-set next-agreement-id (+ agreement-id u1))
          
          (ok agreement-id)
        )
      )
    )
  )
)

;; Record IP usage
(define-public (record-creative-utilization
                (record-id uint)
                (agreement-id (optional uint))
                (utilization-type (string-ascii 32))
                (service-platform (string-ascii 64))
                (utilization-hash (buff 32))
                (income-generated (optional uint)))
  (let
    ((validated-record-id-resp (validate-record-id record-id))
     (validated-utilization-type-resp (validate-utilization-type utilization-type)))
    
    ;; Validate parameters
    (asserts! (is-ok validated-record-id-resp)
              (err (unwrap-err! validated-record-id-resp (err u"Invalid registration ID"))))
    (asserts! (is-ok validated-utilization-type-resp)
              (err (unwrap-err! validated-utilization-type-resp (err u"Invalid usage type"))))
    
    (let ((validated-record-id (unwrap-panic validated-record-id-resp))
          (validated-utilization-type (unwrap-panic validated-utilization-type-resp)))
      
      ;; Get registration and usage counter
      (let ((registration (unwrap! (map-get? creative-registrations
                                  { record-id: validated-record-id })
                                 (err u"Registration not found")))
            (utilization-counter (unwrap! (map-get? next-utilization-id
                                  { record-id: validated-record-id })
                                    (err u"Counter not found")))
            (utilization-id (get id utilization-counter)))
        
        ;; Validate license if provided
        (if (is-some agreement-id)
            (let ((agreement-id-value (unwrap-panic agreement-id))
                  (validated-agreement-id-resp (validate-agreement-id (unwrap-panic agreement-id))))
              
              (asserts! (is-ok validated-agreement-id-resp)
                        (err (unwrap-err! validated-agreement-id-resp (err u"Invalid license ID"))))
              
              (let ((validated-agreement-id (unwrap-panic validated-agreement-id-resp))
                    (license (unwrap! (map-get? issued-licenses
                                      { agreement-id: validated-agreement-id })
                                    (err u"License not found"))))
                ;; Check license validity
                (asserts! (and (is-eq (get record-id license) validated-record-id)
                              (is-eq (get grantee license) tx-sender))
                          (err u"Invalid license for this usage"))
                (asserts! (get operational license) (err u"License not active"))
                (asserts! (not (get cancelled license)) (err u"License revoked"))
                
                ;; Check license expiration
                (if (is-some (get terminates-at license))
                    (asserts! (< block-height (unwrap-panic (get terminates-at license)))
                              (err u"License expired"))
                    true)
                
                ;; Check usage limits
                (if (is-some (get max-utilization license))
                    (asserts! (< (get utilization-counter license) (unwrap-panic (get max-utilization license)))
                              (err u"Usage limit exceeded"))
                    true)
                
                ;; Update usage counter for license
                (map-set issued-licenses
                  { agreement-id: validated-agreement-id }
                  (merge license { utilization-counter: (+ (get utilization-counter license) u1) })
                )
              )
            )
            ;; If no license provided, ensure the work is public domain
            (asserts! (get open-domain registration) (err u"Non-public domain works require a license"))
        )
        
        ;; Create the usage record
        (map-set creative-utilization-logs
          { record-id: validated-record-id, utilization-id: utilization-id }
          {
            grantee: tx-sender,
            agreement-id: agreement-id,
            utilization-type: validated-utilization-type,
            service-platform: service-platform,
            utilization-hash: utilization-hash,
            log-timestamp: block-height,
            income-generated: income-generated,
            validated: false,
            validator: none
          }
        )
        
        ;; Increment usage counter
        (map-set next-utilization-id
          { record-id: validated-record-id }
          { id: (+ utilization-id u1) }
        )
        
        ;; If revenue was generated, process royalty payment
        (if (and (is-some income-generated) (> (unwrap-panic income-generated) u0))
            (record-utilization-compensation validated-record-id utilization-id (unwrap-panic income-generated))
            (ok utilization-id))
      )
    )
  )
)

;; Record royalty from usage revenue
(define-public (record-utilization-compensation (record-id uint) (utilization-id uint) (income uint))
  (let
    ((validated-record-id-resp (validate-record-id record-id)))
    
    ;; Validate registration ID
    (asserts! (is-ok validated-record-id-resp)
              (err (unwrap-err! validated-record-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-record-id (unwrap-panic validated-record-id-resp)))
      ;; Validate usage ID with the unwrapped registration ID
      (let ((validated-utilization-id-resp (validate-utilization-id validated-record-id utilization-id)))
        
        ;; Check if usage ID is valid
        (asserts! (is-ok validated-utilization-id-resp)
                  (err (unwrap-err! validated-utilization-id-resp (err u"Invalid usage ID"))))
        
        (let ((validated-utilization-id (unwrap-panic validated-utilization-id-resp))
              (standard-compensation-rate u1000)  ;; 10% standard rate
              (compensation-amount (/ (* income standard-compensation-rate) u10000))
              (transaction-id (var-get next-transaction-id)))
          
          ;; Create payment record
          (map-set compensation-payments
            { transaction-id: transaction-id }
            {
              record-id: validated-record-id,
              agreement-id: none,
              contributor: tx-sender,
              transaction-amount: compensation-amount,
              transaction-timestamp: block-height,
              utilization-id: (some validated-utilization-id),
              transaction-type: "royalty",
              allocated: false
            }
          )
          
          ;; Increment payment ID counter
          (var-set next-transaction-id (+ transaction-id u1))
          
          ;; Transfer royalty payment
          (asserts! (is-ok (stx-transfer? compensation-amount tx-sender (as-contract tx-sender)))
                    (err u"Royalty payment transfer failed"))
          
          ;; Mark as distributed
          (map-set compensation-payments
            { transaction-id: transaction-id }
            (merge (unwrap-panic (map-get? compensation-payments { transaction-id: transaction-id }))
              { allocated: true })
          )
          
          (ok transaction-id)
        )
      )
    )
  )
)

;; Verify IP usage
(define-public (verify-creative-utilization (record-id uint) (utilization-id uint))
  (let
    ((validated-record-id-resp (validate-record-id record-id)))
    
    ;; Validate registration ID
    (asserts! (is-ok validated-record-id-resp)
              (err (unwrap-err! validated-record-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-record-id (unwrap-panic validated-record-id-resp)))
      ;; Validate usage ID with the unwrapped registration ID
      (let ((validated-utilization-id-resp (validate-utilization-id validated-record-id utilization-id)))
        
        ;; Check if usage ID is valid
        (asserts! (is-ok validated-utilization-id-resp)
                  (err (unwrap-err! validated-utilization-id-resp (err u"Invalid usage ID"))))
        
        (let ((validated-utilization-id (unwrap-panic validated-utilization-id-resp))
              (registration (unwrap! (map-get? creative-registrations
                                      { record-id: validated-record-id })
                                     (err u"Registration not found")))
              (usage (unwrap! (map-get? creative-utilization-logs
                              { record-id: validated-record-id, utilization-id: validated-utilization-id })
                            (err u"Usage not found"))))
          
          ;; Validate
          (asserts! (or (is-eq tx-sender (get originator registration))
                       (is-creative-holder validated-record-id tx-sender))
                    (err u"Not authorized to verify usage"))
          
          ;; Update usage verification
          (map-set creative-utilization-logs
            { record-id: validated-record-id, utilization-id: validated-utilization-id }
            (merge usage {
              validated: true,
              validator: (some tx-sender)
            })
          )
          
          (ok true)
        )
      )
    )
  )
)

;; Check if principal is an IP owner
(define-private (is-creative-holder (record-id uint) (user principal))
  (is-some (map-get? creative-ownership { record-id: record-id, holder: user }))
)

;; Transfer IP ownership shares
(define-public (transfer-creative-shares
                (record-id uint)
                (beneficiary principal)
                (ownership-percentage uint))
  (let
    ((validated-record-id-resp (validate-record-id record-id)))
    
    ;; Validate registration ID
    (asserts! (is-ok validated-record-id-resp)
              (err (unwrap-err! validated-record-id-resp (err u"Invalid registration ID"))))
    
    (let ((validated-record-id (unwrap-panic validated-record-id-resp))
          (registration (unwrap! (map-get? creative-registrations
                                { record-id: (unwrap-panic validated-record-id-resp) })
                               (err u"Registration not found")))
          (sender-ownership (unwrap! (map-get? creative-ownership
                                    { record-id: (unwrap-panic validated-record-id-resp), holder: tx-sender })
                                  (err u"No ownership found")))
          (beneficiary-ownership (map-get? creative-ownership
                               { record-id: (unwrap-panic validated-record-id-resp), holder: beneficiary })))
      
      ;; Validate
      (asserts! (is-eq (get record-status registration) "registered")
                 (err u"Registration not in valid state"))
      (asserts! (<= ownership-percentage (get ownership-percentage sender-ownership))
                 (err u"Insufficient ownership shares"))
      (asserts! (> ownership-percentage u0)
                 (err u"Share percentage must be greater than zero"))
      
      ;; Update sender's ownership
      (map-set creative-ownership
        { record-id: validated-record-id, holder: tx-sender }
        (merge sender-ownership
          { ownership-percentage: (- (get ownership-percentage sender-ownership) ownership-percentage) }
        )
      )
      
      ;; Update or create recipient's ownership
      (if (is-some beneficiary-ownership)
          (map-set creative-ownership
            { record-id: validated-record-id, holder: beneficiary }
            (merge (unwrap-panic beneficiary-ownership)
              {
                ownership-percentage: (+ (get ownership-percentage (unwrap-panic beneficiary-ownership))
                                   ownership-percentage),
                obtained-at: block-height,
                obtained-from: (some tx-sender)
              }
            )
          )
          (map-set creative-ownership
            { record-id: validated-record-id, holder: beneficiary }
            {
              ownership-percentage: ownership-percentage,
              obtained-at: block-height,
              obtained-from: (some tx-sender)
            }
          )
      )
      
      (ok true)
    )
  )
)