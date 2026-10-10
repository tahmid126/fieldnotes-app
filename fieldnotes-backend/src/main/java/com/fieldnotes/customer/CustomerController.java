package com.fieldnotes.customer;

import com.fieldnotes.common.dto.ApiResponse;
import com.fieldnotes.customer.dto.CustomerRequest;
import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.security.SecurityUtils;
import com.fieldnotes.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerService customerService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<CustomerResponse>>> getAllCustomers() {
        User user = SecurityUtils.getCurrentUser();
        List<CustomerResponse> customers = customerService.getAllCustomers(user);
        return ResponseEntity.ok(ApiResponse.success(customers));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CustomerResponse>> getCustomerById(@PathVariable UUID id) {
        User user = SecurityUtils.getCurrentUser();
        CustomerResponse customer = customerService.getCustomerById(id, user);
        return ResponseEntity.ok(ApiResponse.success(customer));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CustomerResponse>> createCustomer(@Valid @RequestBody CustomerRequest request) {
        User user = SecurityUtils.getCurrentUser();
        CustomerResponse created = customerService.createCustomer(request, user);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Customer created successfully", created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CustomerResponse>> updateCustomer(
            @PathVariable UUID id,
            @Valid @RequestBody CustomerRequest request) {
        User user = SecurityUtils.getCurrentUser();
        CustomerResponse updated = customerService.updateCustomer(id, request, user);
        return ResponseEntity.ok(ApiResponse.success("Customer updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCustomer(@PathVariable UUID id) {
        User user = SecurityUtils.getCurrentUser();
        customerService.deleteCustomer(id, user);
        return ResponseEntity.ok(ApiResponse.success("Customer deleted successfully", null));
    }
}
