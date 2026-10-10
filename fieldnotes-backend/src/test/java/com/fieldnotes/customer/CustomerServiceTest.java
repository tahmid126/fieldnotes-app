package com.fieldnotes.customer;

import com.fieldnotes.common.exception.ResourceNotFoundException;
import com.fieldnotes.customer.dto.CustomerRequest;
import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {

    @Mock
    private CustomerRepository customerRepository;

    @InjectMocks
    private CustomerService customerService;

    private User testUser;
    private Customer testCustomer;
    private UUID customerId;

    @BeforeEach
    void setUp() {
        testUser = User.builder()
                .id(UUID.randomUUID())
                .email("engineer@telecom.com")
                .name("Field Engineer")
                .build();

        customerId = UUID.randomUUID();
        testCustomer = Customer.builder()
                .id(customerId)
                .name("FiberLink Corp")
                .contactInformation("contact@fiberlink.com")
                .user(testUser)
                .deleted(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    @Test
    void createCustomer_SavesAndReturnsResponse() {
        CustomerRequest request = new CustomerRequest();
        request.setName("FiberLink Corp");
        request.setContactInformation("contact@fiberlink.com");

        when(customerRepository.save(any(Customer.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CustomerResponse response = customerService.createCustomer(request, testUser);

        assertNotNull(response);
        assertEquals("FiberLink Corp", response.getName());
        assertEquals("contact@fiberlink.com", response.getContactInformation());
        verify(customerRepository, times(1)).save(any(Customer.class));
    }

    @Test
    void getAllCustomers_ReturnsActiveUserCustomers() {
        when(customerRepository.findAllByUserIdAndDeletedFalseOrderByNameAsc(testUser.getId()))
                .thenReturn(List.of(testCustomer));

        List<CustomerResponse> responses = customerService.getAllCustomers(testUser);

        assertEquals(1, responses.size());
        assertEquals(customerId, responses.get(0).getId());
        assertEquals("FiberLink Corp", responses.get(0).getName());
    }

    @Test
    void getCustomerById_WhenFound_ReturnsResponse() {
        when(customerRepository.findByIdAndUserIdAndDeletedFalse(customerId, testUser.getId()))
                .thenReturn(Optional.of(testCustomer));

        CustomerResponse response = customerService.getCustomerById(customerId, testUser);

        assertNotNull(response);
        assertEquals(customerId, response.getId());
    }

    @Test
    void getCustomerById_WhenNotFound_ThrowsException() {
        UUID nonExistent = UUID.randomUUID();
        when(customerRepository.findByIdAndUserIdAndDeletedFalse(nonExistent, testUser.getId()))
                .thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> customerService.getCustomerById(nonExistent, testUser));
    }

    @Test
    void deleteCustomer_MarksDeletedTrue() {
        when(customerRepository.findByIdAndUserIdAndDeletedFalse(customerId, testUser.getId()))
                .thenReturn(Optional.of(testCustomer));

        customerService.deleteCustomer(customerId, testUser);

        assertTrue(testCustomer.isDeleted());
        verify(customerRepository, times(1)).save(testCustomer);
    }
}
