package com.fieldnotes.customer;

import com.fieldnotes.common.exception.ResourceNotFoundException;
import com.fieldnotes.customer.dto.CustomerRequest;
import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CustomerService {

    private final CustomerRepository customerRepository;

    @Transactional(readOnly = true)
    public List<CustomerResponse> getAllCustomers(User user) {
        return customerRepository.findAllByUserIdAndDeletedFalseOrderByNameAsc(user.getId())
                .stream()
                .map(CustomerResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public CustomerResponse getCustomerById(UUID id, User user) {
        Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with id: " + id));
        return CustomerResponse.fromEntity(customer);
    }

    @Transactional
    public CustomerResponse createCustomer(CustomerRequest request, User user) {
        Customer customer = Customer.builder()
                .id(request.getId() != null ? request.getId() : UUID.randomUUID())
                .name(request.getName().trim())
                .contactInformation(request.getContactInformation())
                .user(user)
                .deleted(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        Customer saved = customerRepository.save(customer);
        return CustomerResponse.fromEntity(saved);
    }

    @Transactional
    public CustomerResponse updateCustomer(UUID id, CustomerRequest request, User user) {
        Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with id: " + id));

        customer.setName(request.getName().trim());
        customer.setContactInformation(request.getContactInformation());
        customer.setUpdatedAt(LocalDateTime.now());

        Customer updated = customerRepository.save(customer);
        return CustomerResponse.fromEntity(updated);
    }

    @Transactional
    public void deleteCustomer(UUID id, User user) {
        Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with id: " + id));

        // Soft delete so offline sync knows this was deleted
        customer.setDeleted(true);
        customer.setUpdatedAt(LocalDateTime.now());
        customerRepository.save(customer);
    }
}
