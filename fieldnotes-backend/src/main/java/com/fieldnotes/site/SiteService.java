package com.fieldnotes.site;

import com.fieldnotes.common.exception.ResourceNotFoundException;
import com.fieldnotes.customer.Customer;
import com.fieldnotes.customer.CustomerRepository;
import com.fieldnotes.site.dto.SiteRequest;
import com.fieldnotes.site.dto.SiteResponse;
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
public class SiteService {

    private final SiteRepository siteRepository;
    private final CustomerRepository customerRepository;

    @Transactional(readOnly = true)
    public List<SiteResponse> getAllSites(User user) {
        return siteRepository.findAllByUserIdAndDeletedFalseOrderByNameAsc(user.getId())
                .stream()
                .map(SiteResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SiteResponse> getSitesByCustomerId(UUID customerId, User user) {
        // verify customer belongs to user
        customerRepository.findByIdAndUserIdAndDeletedFalse(customerId, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with id: " + customerId));

        return siteRepository.findAllByCustomerIdAndUserIdAndDeletedFalseOrderByNameAsc(customerId, user.getId())
                .stream()
                .map(SiteResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public SiteResponse getSiteById(UUID id, User user) {
        Site site = siteRepository.findByIdAndUserIdAndDeletedFalse(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + id));
        return SiteResponse.fromEntity(site);
    }

    @Transactional
    public SiteResponse createSite(SiteRequest request, User user) {
        Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(request.getCustomerId(), user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with id: " + request.getCustomerId()));

        Site site = Site.builder()
                .id(request.getId() != null ? request.getId() : UUID.randomUUID())
                .name(request.getName().trim())
                .address(request.getAddress().trim())
                .customer(customer)
                .user(user)
                .deleted(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        Site saved = siteRepository.save(site);
        return SiteResponse.fromEntity(saved);
    }

    @Transactional
    public SiteResponse updateSite(UUID id, SiteRequest request, User user) {
        Site site = siteRepository.findByIdAndUserIdAndDeletedFalse(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + id));

        Customer customer = customerRepository.findByIdAndUserIdAndDeletedFalse(request.getCustomerId(), user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with id: " + request.getCustomerId()));

        site.setName(request.getName().trim());
        site.setAddress(request.getAddress().trim());
        site.setCustomer(customer);
        site.setUpdatedAt(LocalDateTime.now());

        Site updated = siteRepository.save(site);
        return SiteResponse.fromEntity(updated);
    }

    @Transactional
    public void deleteSite(UUID id, User user) {
        Site site = siteRepository.findByIdAndUserIdAndDeletedFalse(id, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Site not found with id: " + id));

        site.setDeleted(true);
        site.setUpdatedAt(LocalDateTime.now());
        siteRepository.save(site);
    }
}
