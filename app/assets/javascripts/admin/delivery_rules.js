// Complete state-cities mapping for India
const INDIAN_STATES_CITIES = {
  'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Tirupati', 'Guntur', 'Kakinada', 'Nellore', 'Kurnool', 'Anantapur', 'Rajahmundry', 'Kadapa'],
  'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Tawang', 'Bomdila', 'Pasighat', 'Tezu', 'Ziro', 'Roing'],
  'Assam': ['Guwahati', 'Dibrugarh', 'Jorhat', 'Silchar', 'Tezpur', 'Tinsukia', 'Nagaon', 'Bongaigaon'],
  'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Darbhanga', 'Purnia', 'Arrah', 'Begusarai', 'Katihar'],
  'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Durg', 'Korba', 'Rajnandgaon', 'Raigarh', 'Jagdalpur'],
  'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Ponda', 'Mapusa', 'Bicholim', 'Curchorem'],
  'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Gandhinagar', 'Junagadh', 'Anand', 'Nadiad', 'Morbi', 'Bharuch'],
  'Haryana': ['Gurgaon', 'Faridabad', 'Rohtak', 'Panipat', 'Karnal', 'Sonipat', 'Ambala', 'Hisar', 'Panchkula', 'Yamunanagar'],
  'Himachal Pradesh': ['Shimla', 'Dharamshala', 'Manali', 'Solan', 'Mandi', 'Kullu', 'Bilaspur', 'Hamirpur', 'Kangra'],
  'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Hazaribagh', 'Deoghar', 'Giridih', 'Ramgarh'],
  'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum', 'Davangere', 'Tumkur', 'Udupi', 'Shimoga', 'Gulbarga', 'Bellary', 'Bijapur', 'Hassan'],
  'Kerala': ['Kochi', 'Thiruvananthapuram', 'Kozhikode', 'Thrissur', 'Kollam', 'Kannur', 'Kottayam', 'Palakkad', 'Alappuzha', 'Malappuram'],
  'Madhya Pradesh': ['Bhopal', 'Indore', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar', 'Dewas', 'Satna', 'Ratlam', 'Rewa', 'Murwara'],
  'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad', 'Solapur', 'Thane', 'Kolhapur', 'Navi Mumbai', 'Kalyan-Dombivli', 'Vasai-Virar', 'Amravati', 'Nanded', 'Sangli', 'Jalgaon', 'Akola', 'Latur'],
  'Manipur': ['Imphal', 'Thoubal', 'Churachandpur', 'Bishnupur', 'Kakching'],
  'Meghalaya': ['Shillong', 'Tura', 'Jowai', 'Cherrapunji', 'Nongstoin'],
  'Mizoram': ['Aizawl', 'Lunglei', 'Champhai', 'Serchhip', 'Kolasib'],
  'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang', 'Wokha', 'Mon'],
  'Odisha': ['Bhubaneswar', 'Cuttack', 'Puri', 'Rourkela', 'Sambalpur', 'Berhampur', 'Balasore', 'Bhadrak'],
  'Punjab': ['Amritsar', 'Ludhiana', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali', 'Pathankot', 'Hoshiarpur', 'Moga'],
  'Rajasthan': ['Jaipur', 'Udaipur', 'Jodhpur', 'Kota', 'Ajmer', 'Bikaner', 'Alwar', 'Bhilwara', 'Bharatpur', 'Sikar', 'Sri Ganganagar', 'Pali'],
  'Sikkim': ['Gangtok', 'Namchi', 'Mangan', 'Pelling', 'Gyalshing', 'Rangpo'],
  'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Tiruchirappalli', 'Tirunelveli', 'Erode', 'Vellore', 'Thoothukudi', 'Thanjavur', 'Dindigul', 'Tiruppur'],
  'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Khammam', 'Karimnagar', 'Secunderabad', 'Mahbubnagar', 'Nalgonda', 'Adilabad'],
  'Tripura': ['Agartala', 'Dharmanagar', 'Udaipur', 'Belonia', 'Kailashahar', 'Ambassa'],
  'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Agra', 'Varanasi', 'Allahabad', 'Meerut', 'Ghaziabad', 'Noida', 'Greater Noida', 'Bareilly', 'Aligarh', 'Moradabad', 'Gorakhpur', 'Saharanpur', 'Faizabad', 'Jhansi', 'Muzaffarnagar', 'Mathura'],
  'Uttarakhand': ['Dehradun', 'Haridwar', 'Rishikesh', 'Nainital', 'Mussoorie', 'Roorkee', 'Haldwani', 'Rudrapur', 'Kashipur'],
  'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri', 'Darjeeling', 'Haldia', 'Kharagpur', 'Bardhaman', 'Malda', 'Baharampur'],
  'Andaman and Nicobar Islands': ['Port Blair', 'Diglipur', 'Mayabunder', 'Rangat', 'Hut Bay'],
  'Chandigarh': ['Chandigarh'],
  'Dadra and Nagar Haveli and Daman and Diu': ['Daman', 'Diu', 'Silvassa'],
  'Delhi': ['New Delhi', 'South Delhi', 'North Delhi', 'East Delhi', 'West Delhi', 'Central Delhi', 'Dwarka', 'Rohini', 'Saket', 'Karol Bagh', 'Lajpat Nagar'],
  'Jammu and Kashmir': ['Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Udhampur', 'Kathua', 'Sopore', 'Poonch'],
  'Ladakh': ['Leh', 'Kargil', 'Diskit', 'Padum'],
  'Lakshadweep': ['Kavaratti', 'Agatti', 'Amini', 'Andrott'],
  'Puducherry': ['Puducherry', 'Karaikal', 'Mahe', 'Yanam']
};

// Initialize delivery rules functionality
function initializeDeliveryRules() {
  // Initialize all existing rules
  document.querySelectorAll('.delivery-rule-row').forEach(ruleRow => {
    initializeRuleRow(ruleRow);
  });
}

// Initialize a single delivery rule row
function initializeRuleRow(ruleRow) {
  const ruleTypeSelect = ruleRow.querySelector('select[name*="rule_type"]');

  if (ruleTypeSelect) {
    // Set up change handler for rule type
    ruleTypeSelect.addEventListener('change', function() {
      handleRuleTypeChange(ruleRow, this.value);
    });

    // Trigger initial setup
    handleRuleTypeChange(ruleRow, ruleTypeSelect.value);
  }

  // Initialize multiselect dropdowns
  initializeMultiselects(ruleRow);

  // Set up location data update handlers
  setupLocationDataHandlers(ruleRow);
}

// Handle rule type change
function handleRuleTypeChange(ruleRow, ruleType) {
  const locationGroup = ruleRow.querySelector('.location-data-group');
  const stateGroup = ruleRow.querySelector('.state-select-group');
  const cityGroup = ruleRow.querySelector('.city-select-group');
  const pincodeGroup = ruleRow.querySelector('.pincode-input-group');
  const filteredCitiesGroup = ruleRow.querySelector('.filtered-cities-group');
  const statesFilterGroup = ruleRow.querySelector('.states-filter-group');

  // Hide all groups first
  [stateGroup, cityGroup, pincodeGroup, filteredCitiesGroup, statesFilterGroup].forEach(group => {
    if (group) group.style.display = 'none';
  });

  if (ruleType === 'everywhere') {
    if (locationGroup) locationGroup.style.display = 'none';
  } else {
    if (locationGroup) locationGroup.style.display = 'block';

    switch(ruleType) {
      case 'state':
        if (stateGroup) {
          stateGroup.style.display = 'block';
          setupStateSelection(ruleRow);
        }
        break;
      case 'city':
        if (cityGroup) {
          cityGroup.style.display = 'block';
          if (statesFilterGroup) {
            statesFilterGroup.style.display = 'block';
            setupCitySelection(ruleRow);
          }
        }
        break;
      case 'pincode':
        if (pincodeGroup) {
          pincodeGroup.style.display = 'block';
          setupPincodeInput(ruleRow);
        }
        break;
    }
  }

  updateLocationData(ruleRow);
}

// Initialize multiselect dropdowns with Select2
function initializeMultiselects(ruleRow) {
  const selects = {
    states: ruleRow.querySelector('.multiselect-states'),
    cities: ruleRow.querySelector('.multiselect-cities'),
    filteredCities: ruleRow.querySelector('.multiselect-filtered-cities'),
    stateFilter: ruleRow.querySelector('.multiselect-state-filter')
  };

  // Initialize Select2 for states
  if (selects.states && !$(selects.states).data('select2')) {
    $(selects.states).select2({
      theme: 'bootstrap-5',
      placeholder: 'Select states...',
      allowClear: true,
      closeOnSelect: false,
      width: '100%',
      dropdownParent: $(ruleRow)
    });
  }

  // Initialize Select2 for cities
  if (selects.cities && !$(selects.cities).data('select2')) {
    $(selects.cities).select2({
      theme: 'bootstrap-5',
      placeholder: 'Select cities...',
      allowClear: true,
      closeOnSelect: false,
      width: '100%',
      dropdownParent: $(ruleRow)
    });
  }

  // Initialize Select2 for filtered cities
  if (selects.filteredCities && !$(selects.filteredCities).data('select2')) {
    $(selects.filteredCities).select2({
      theme: 'bootstrap-5',
      placeholder: 'Select cities from chosen states...',
      allowClear: true,
      closeOnSelect: false,
      width: '100%',
      dropdownParent: $(ruleRow)
    });
  }

  // Initialize Select2 for state filter
  if (selects.stateFilter && !$(selects.stateFilter).data('select2')) {
    $(selects.stateFilter).select2({
      theme: 'bootstrap-5',
      placeholder: 'Filter by states...',
      allowClear: true,
      closeOnSelect: false,
      width: '100%',
      dropdownParent: $(ruleRow)
    });
  }
}

// Setup state selection with filtered cities
function setupStateSelection(ruleRow) {
  const stateSelect = ruleRow.querySelector('.multiselect-states');
  const filteredCitiesGroup = ruleRow.querySelector('.filtered-cities-group');
  const filteredCitiesSelect = ruleRow.querySelector('.multiselect-filtered-cities');

  if (!stateSelect) return;

  $(stateSelect).off('change').on('change', function() {
    const selectedStates = $(this).val() || [];

    if (selectedStates.length > 0 && filteredCitiesGroup && filteredCitiesSelect) {
      filteredCitiesGroup.style.display = 'block';

      // Clear and rebuild cities dropdown
      $(filteredCitiesSelect).empty();

      let cities = [];
      selectedStates.forEach(state => {
        if (INDIAN_STATES_CITIES[state]) {
          cities = cities.concat(INDIAN_STATES_CITIES[state]);
        }
      });

      // Remove duplicates and sort
      cities = [...new Set(cities)].sort();

      // Add cities to dropdown
      cities.forEach(city => {
        const option = new Option(city, city);
        $(filteredCitiesSelect).append(option);
      });

      // Refresh Select2
      $(filteredCitiesSelect).trigger('change.select2');
    } else if (filteredCitiesGroup) {
      filteredCitiesGroup.style.display = 'none';
    }

    updateLocationData(ruleRow);
  });
}

// Setup city selection with state filter
function setupCitySelection(ruleRow) {
  const stateFilterSelect = ruleRow.querySelector('.multiselect-state-filter');
  const citySelect = ruleRow.querySelector('.multiselect-cities');

  if (!stateFilterSelect || !citySelect) return;

  $(stateFilterSelect).off('change').on('change', function() {
    const selectedStates = $(this).val() || [];
    const currentSelectedCities = $(citySelect).val() || [];

    if (selectedStates.length > 0) {
      // Clear and rebuild cities dropdown
      $(citySelect).empty();

      let cities = [];
      selectedStates.forEach(state => {
        if (INDIAN_STATES_CITIES[state]) {
          cities = cities.concat(INDIAN_STATES_CITIES[state]);
        }
      });

      // Remove duplicates and sort
      cities = [...new Set(cities)].sort();

      // Add cities to dropdown
      cities.forEach(city => {
        const option = new Option(city, city, false, currentSelectedCities.includes(city));
        $(citySelect).append(option);
      });
    } else {
      // Show all cities if no state filter
      $(citySelect).empty();

      let allCities = [];
      Object.values(INDIAN_STATES_CITIES).forEach(stateCities => {
        allCities = allCities.concat(stateCities);
      });

      // Remove duplicates and sort
      allCities = [...new Set(allCities)].sort();

      // Add all cities
      allCities.forEach(city => {
        const option = new Option(city, city, false, currentSelectedCities.includes(city));
        $(citySelect).append(option);
      });
    }

    // Refresh Select2
    $(citySelect).trigger('change.select2');
  });
}

// Setup pincode input
function setupPincodeInput(ruleRow) {
  const pincodeInput = ruleRow.querySelector('textarea[name*="location_data_pincodes"]');

  if (!pincodeInput) return;

  // Add validation for pincode format
  pincodeInput.addEventListener('input', function() {
    // Remove any non-digit and non-comma characters
    let value = this.value.replace(/[^\d,\s]/g, '');

    // Split by comma and validate each pincode
    let pincodes = value.split(',').map(p => p.trim());
    let validPincodes = pincodes.filter(p => {
      return p === '' || /^\d{0,6}$/.test(p);
    });

    if (pincodes.length !== validPincodes.length) {
      this.classList.add('is-invalid');
    } else {
      this.classList.remove('is-invalid');
    }

    updateLocationData(ruleRow);
  });
}

// Setup handlers to update location data
function setupLocationDataHandlers(ruleRow) {
  // States change handler
  const stateSelect = ruleRow.querySelector('.multiselect-states');
  if (stateSelect) {
    $(stateSelect).on('change', () => updateLocationData(ruleRow));
  }

  // Cities change handler
  const citySelect = ruleRow.querySelector('.multiselect-cities');
  if (citySelect) {
    $(citySelect).on('change', () => updateLocationData(ruleRow));
  }

  // Filtered cities change handler
  const filteredCitiesSelect = ruleRow.querySelector('.multiselect-filtered-cities');
  if (filteredCitiesSelect) {
    $(filteredCitiesSelect).on('change', () => updateLocationData(ruleRow));
  }

  // Pincode input handler
  const pincodeInput = ruleRow.querySelector('textarea[name*="location_data_pincodes"]');
  if (pincodeInput) {
    pincodeInput.addEventListener('input', () => updateLocationData(ruleRow));
  }
}

// Update the hidden location_data field with current selections
function updateLocationData(ruleRow) {
  const ruleTypeSelect = ruleRow.querySelector('select[name*="rule_type"]');
  const hiddenField = ruleRow.querySelector('.location-data-hidden');

  if (!ruleTypeSelect || !hiddenField) return;

  const ruleType = ruleTypeSelect.value;
  let locationData = [];

  switch(ruleType) {
    case 'state':
      const stateSelect = ruleRow.querySelector('.multiselect-states');
      const filteredCitiesSelect = ruleRow.querySelector('.multiselect-filtered-cities');

      if (stateSelect) {
        const states = $(stateSelect).val() || [];
        const cities = filteredCitiesSelect ? ($(filteredCitiesSelect).val() || []) : [];

        // If cities are selected, use them; otherwise use states
        if (cities.length > 0) {
          locationData = { states: states, cities: cities };
        } else {
          locationData = states;
        }
      }
      break;

    case 'city':
      const citySelect = ruleRow.querySelector('.multiselect-cities');
      if (citySelect) {
        locationData = $(citySelect).val() || [];
      }
      break;

    case 'pincode':
      const pincodeInput = ruleRow.querySelector('textarea[name*="location_data_pincodes"]');
      if (pincodeInput && pincodeInput.value) {
        locationData = pincodeInput.value
          .split(',')
          .map(p => p.trim())
          .filter(p => /^\d{6}$/.test(p));
      }
      break;

    case 'everywhere':
      locationData = [];
      break;
  }

  hiddenField.value = JSON.stringify(locationData);
}

// Add new delivery rule
function addDeliveryRule() {
  const container = document.getElementById('delivery-rules-container');
  const template = document.getElementById('delivery-rule-template');

  if (!container || !template) return;

  const newRule = template.content.cloneNode(true);
  const ruleRow = newRule.querySelector('.delivery-rule-row');

  if (!ruleRow) return;

  // Replace NEW_RECORD with timestamp-based index
  const newIndex = Date.now();
  ruleRow.innerHTML = ruleRow.innerHTML.replace(/NEW_RECORD/g, newIndex);

  // Append to container
  container.appendChild(newRule);

  // Initialize the new row
  const addedRow = container.lastElementChild;
  initializeRuleRow(addedRow);
}

// Remove delivery rule
function removeDeliveryRule(button) {
  const ruleRow = button.closest('.delivery-rule-row');

  if (!ruleRow) return;

  // Destroy Select2 instances
  const selects = ruleRow.querySelectorAll('.select2-hidden-accessible');
  selects.forEach(select => {
    if ($(select).data('select2')) {
      $(select).select2('destroy');
    }
  });

  // Check if this is an existing rule (has _destroy field)
  const destroyField = ruleRow.querySelector('input[name*="_destroy"]');

  if (destroyField) {
    // Mark for destruction instead of removing
    destroyField.value = '1';
    ruleRow.style.display = 'none';
  } else {
    // Remove new rule completely
    ruleRow.remove();
  }
}

// Initialize on document ready
document.addEventListener('DOMContentLoaded', function() {
  // Check if we're on the product form page
  if (document.querySelector('#delivery-rules-container')) {
    initializeDeliveryRules();

    // Add button handler
    const addButton = document.getElementById('add-delivery-rule');
    if (addButton) {
      addButton.addEventListener('click', addDeliveryRule);
    }

    // Remove button handlers (use delegation)
    document.addEventListener('click', function(e) {
      if (e.target.classList.contains('remove-delivery-rule') ||
          e.target.closest('.remove-delivery-rule')) {
        e.preventDefault();
        removeDeliveryRule(e.target);
      }
    });
  }
});

// Export for use in other scripts if needed
window.DeliveryRules = {
  initialize: initializeDeliveryRules,
  addRule: addDeliveryRule,
  STATES_CITIES: INDIAN_STATES_CITIES
};