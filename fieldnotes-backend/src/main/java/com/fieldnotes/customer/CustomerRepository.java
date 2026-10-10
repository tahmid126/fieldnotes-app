package com.fieldnotes.customer;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, UUID> {

    List<Customer> findAllByUserIdAndDeletedFalseOrderByNameAsc(UUID userId);

    Optional<Customer> findByIdAndUserId(UUID id, UUID userId);

    Optional<Customer> findByIdAndUserIdAndDeletedFalse(UUID id, UUID userId);

    List<Customer> findByUserIdAndUpdatedAtAfter(UUID userId, LocalDateTime updatedAt);

    List<Customer> findAllByUserId(UUID userId);
}
